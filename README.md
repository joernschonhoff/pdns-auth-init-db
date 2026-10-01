# pdns-auth-init-db

Small init-container image to initialize the backend database for a PowerDNS authoritative instance (pdns-auth). Intended to run in docker-compose or Kubernetes as an `initContainer`/one-shot service that ensures the database and schema exist before the main `pdns-auth` container starts.

## Purpose & Warning

This is a **hobby / learning project**. It is **not intended for production use** — it lacks typical hardening, monitoring, and operational features. Use at your own risk.

This project is **not affiliated with, endorsed by, or associated with PowerDNS.com B.V.** in any form. "PowerDNS" is a trademark of PowerDNS.com B.V.; this image simply packages the official PowerDNS Authoritative schema files and applies them with standard database client tools.

## Features

- Minimal purpose-built image based on Alpine, containing only `mariadb-client`, `postgresql-client`, and `sqlite` clients
- Schema files for all three backends (`schema.mysql.sql`, `schema.pgsql.sql`, `schema.sqlite3.sql`) are extracted from the official PowerDNS Authoritative release tarball at build time
- Waits for the configured database server to become available before attempting initialization (MySQL/PostgreSQL only)
- Creates the database if it does not exist
- Applies the schema only if no tables are present yet, so it is safe to run on every container start/restart
- Backend is selected via `PDNS_LAUNCH` (`gmysql`, `gpgsql`, or `gsqlite3`), matching PowerDNS's own configuration variable

## Supported backends & environment variables

### `gmysql` (MySQL/MariaDB)

| Variable | Default | Description |
|---|---|---|
| `PDNS_GMYSQL_HOST` | — (required) | Database host |
| `PDNS_GMYSQL_PORT` | `3306` | Database port |
| `PDNS_GMYSQL_USER` | `root` | Database user |
| `PDNS_GMYSQL_PASSWORD` | — | Database password |
| `PDNS_GMYSQL_DBNAME` | `pdns` | Database name |
| `PDNS_GMYSQL_SSL` | `no` | Set to any other value to enable TLS |

### `gpgsql` (PostgreSQL)

| Variable | Default | Description |
|---|---|---|
| `PDNS_GPGSQL_HOST` | — (required) | Database host |
| `PDNS_GPGSQL_PORT` | `5432` | Database port |
| `PDNS_GPGSQL_USER` | `postgres` | Database user |
| `PDNS_GPGSQL_PASSWORD` | — | Database password |
| `PDNS_GPGSQL_DB` | `pdns` | Database name |

### `gsqlite3` (SQLite)

| Variable | Default | Description |
|---|---|---|
| `PDNS_GSQLITE3_DATABASE` | `/data/pdns.sqlite3` | Path to the SQLite database file |

## Quick usage

### Docker compose

Run `pdns-auth-init-db` once before the main `pdns-auth` container, sharing a volume (for `gsqlite3`) or pointing both at the same database server (for `gmysql`/`gpgsql`).

```yaml
services:
  pdns-auth-init-db:
    image: registry.gitlab.com/joern_schonhoff/pdns-auth-init-db:latest
    environment:
      - PDNS_LAUNCH=gsqlite3
      - PDNS_GSQLITE3_DATABASE=/data/pdns.sqlite3
    volumes:
      - pdns-auth-data:/data

  pdns-auth:
    image: registry.gitlab.com/joern_schonhoff/pdns-auth-distroless:latest
    volumes:
      - pdns-auth-data:/data
    depends_on:
      pdns-auth-init-db:
        condition: service_completed_successfully

volumes:
  pdns-auth-data:
```

### Kubernetes

Run this image as an `initContainer` so the main pdns-auth pod can start against an already-initialized database:

```yaml
initContainers:
  - name: pdns-auth-init-db
    image: registry.gitlab.com/joern_schonhoff/pdns-auth-init-db:latest
    env:
      - name: PDNS_LAUNCH
        value: gpgsql
      - name: PDNS_GPGSQL_HOST
        value: postgres
      - name: PDNS_GPGSQL_PASSWORD
        valueFrom:
          secretKeyRef:
            name: pdns-db-secret
            key: password
```

Replace the image reference and environment variables for your deployment.

## Version Management

The PowerDNS Authoritative version whose schema files are extracted is stored in the `VERSION` file. When a new version is released:

1. Update the `VERSION` file with the new version number
2. Build and test the image
3. Commit the change

**Automated Updates:** The project is configured for Renovate bot, which will:
- Monitor https://downloads.powerdns.com/releases/ for new PowerDNS Authoritative releases
- Automatically create PRs when new stable versions (e.g., `pdns-5.0.2.tar.bz2`) are detected
- Extract the version number and update the `VERSION` file

## License

MIT

## Author

Joern Schonhoff
