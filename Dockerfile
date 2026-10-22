FROM alpine:3.24.3@sha256:1b7232cda4ca3dc20b5d1247bdc9bfb631f2661d15d323bdd6fccc035ed1a9e7 AS downloader
ARG PDNS_AUTH_VERSION

WORKDIR /src

RUN apk update \
    && apk add --no-cache wget \
    && wget "https://downloads.powerdns.com/releases/pdns-${PDNS_AUTH_VERSION}.tar.bz2" \
    && tar xf pdns-${PDNS_AUTH_VERSION}.tar.bz2

WORKDIR /src/pdns-${PDNS_AUTH_VERSION}

RUN mkdir /runtime \
    && find . -type f -name "schema.*.sql" -exec cp {} /runtime/ \;

FROM alpine:3.24.3@sha256:1b7232cda4ca3dc20b5d1247bdc9bfb631f2661d15d323bdd6fccc035ed1a9e7 AS runtime

RUN apk update \
    && apk add --no-cache \
        mariadb-client \
        postgresql-client \
        sqlite

COPY --from=downloader /runtime/ /schemas/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
