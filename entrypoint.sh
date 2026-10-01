#! /bin/sh
set -e

init_mysql() {
    # Set defaults
    PDNS_GMYSQL_DBNAME="${PDNS_GMYSQL_DBNAME:-pdns}"
    PDNS_GMYSQL_USER="${PDNS_GMYSQL_USER:-root}"
    PDNS_GMYSQL_PORT="${PDNS_GMYSQL_PORT:-3306}"
    PDNS_GMYSQL_SSL="${PDNS_GMYSQL_SSL:-no}"

    MYSQL_COMMAND="mariadb -h ${PDNS_GMYSQL_HOST} -P ${PDNS_GMYSQL_PORT} -u ${PDNS_GMYSQL_USER} -p${PDNS_GMYSQL_PASSWORD}"
    if [ "${PDNS_GMYSQL_SSL}" = "no" ]; then
        MYSQL_COMMAND="${MYSQL_COMMAND} --skip-ssl"
    fi

    # Wait for the mysql server to be available
    echo "Waiting for MySQL server at ${PDNS_GMYSQL_HOST}:${PDNS_GMYSQL_PORT} to be available..."
    until $MYSQL_COMMAND -e 'SELECT 1' 2>/dev/null; do
        echo "MySQL is unavailable - sleeping"
        sleep 2
    done

    # Create database if not exists
    echo "Ensuring database ${PDNS_GMYSQL_DBNAME} exists..."
    $MYSQL_COMMAND -e "CREATE DATABASE IF NOT EXISTS ${PDNS_GMYSQL_DBNAME};"

    # Init the database schema
    echo "Ensuring database schema is initialized..."
    # Check if any tables exist
    TABLE_COUNT=$($MYSQL_COMMAND -D "${PDNS_GMYSQL_DBNAME}" -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${PDNS_GMYSQL_DBNAME}';")
    if [ "$TABLE_COUNT" -eq "0" ]; then
        echo "No tables found in database ${PDNS_GMYSQL_DBNAME}. Initializing schema..."
        $MYSQL_COMMAND "${PDNS_GMYSQL_DBNAME}" < /schemas/schema.mysql.sql
    fi
}

init_pgsql() {
    # Set defaults
    PDNS_GPGSQL_DB="${PDNS_GPGSQL_DB:-pdns}"
    PDNS_GPGSQL_USER="${PDNS_GPGSQL_USER:-postgres}"
    PDNS_GPGSQL_PORT="${PDNS_GPGSQL_PORT:-5432}"

    PGSQL_COMMAND="psql -h ${PDNS_GPGSQL_HOST} -p ${PDNS_GPGSQL_PORT} -U ${PDNS_GPGSQL_USER}"
    export PGPASSWORD="${PDNS_GPGSQL_PASSWORD}"

    # Wait for the postgres server to be available
    echo "Waiting for PostgreSQL server at ${PDNS_GPGSQL_HOST}:${PDNS_GPGSQL_PORT} to be available..."
    until $PGSQL_COMMAND -c '\q' 2>/dev/null; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
    done

    # Create database if not exists
    echo "Ensuring database ${PDNS_GPGSQL_DBNAME} exists..."
    echo "SELECT 'CREATE DATABASE ${PDNS_GPGSQL_DBNAME}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${PDNS_GPGSQL_DBNAME}')\gexec" | $PGSQL_COMMAND

    # Init the database schema
    echo "Ensuring database schema is initialized..."
    # Check if any tables exist
    TABLE_COUNT=$($PGSQL_COMMAND -d "${PDNS_GPGSQL_DBNAME}" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
    if [ "$TABLE_COUNT" -eq "0" ]; then
        echo "No tables found in database ${PDNS_GPGSQL_DBNAME}. Initializing schema..."
        $PGSQL_COMMAND -d "${PDNS_GPGSQL_DBNAME}" < /schemas/schema.pgsql.sql
    fi
}

init_sqlite3() {
    # Set defaults
    PDNS_GSQLITE3_DATABASE="${PDNS_GSQLITE3_DATABASE:-/data/pdns.sqlite3}"

    # Init the database
    echo "Ensuring SQLite3 database is initialized..."
    if [ ! -f "${PDNS_GSQLITE3_DATABASE}" ]; then
        echo "Database file ${PDNS_GSQLITE3_DATABASE} does not exist. Initializing schema..."
        sqlite3 "${PDNS_GSQLITE3_DATABASE}" < /schemas/schema.sqlite3.sql
    else
        # Check if any tables exist
        TABLE_COUNT=$(sqlite3 "${PDNS_GSQLITE3_DATABASE}" "SELECT count(name) FROM sqlite_master WHERE type='table';")
        if [ "$TABLE_COUNT" -eq "0" ]; then
            echo "No tables found in database ${PDNS_GSQLITE3_DATABASE}. Initializing schema..."
            sqlite3 "${PDNS_GSQLITE3_DATABASE}" < /schemas/schema.sqlite3.sql
        fi
    fi

    chmod 0664 "${PDNS_GSQLITE3_DATABASE}"
    chown 1000:1000 "${PDNS_GSQLITE3_DATABASE}"
}

case "${PDNS_LAUNCH}" in
    gmysql)
        init_mysql
        ;;
    gpgsql)
        init_pgsql
        ;;
    gsqlite3)
        init_sqlite3
        ;;
    *)
        echo "Unknown PDNS_LAUNCH value: ${PDNS_LAUNCH}"
        exit 1
        ;;
esac
