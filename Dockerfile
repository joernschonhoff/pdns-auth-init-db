FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS downloader
ARG PDNS_AUTH_VERSION

WORKDIR /src

RUN apk update \
    && apk add --no-cache wget \
    && wget "https://downloads.powerdns.com/releases/pdns-${PDNS_AUTH_VERSION}.tar.bz2" \
    && tar xf pdns-${PDNS_AUTH_VERSION}.tar.bz2

WORKDIR /src/pdns-${PDNS_AUTH_VERSION}

RUN mkdir /runtime \
    && find . -type f -name "schema.*.sql" -exec cp {} /runtime/ \;

FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6 AS runtime

RUN apk update \
    && apk add --no-cache \
        mariadb-client \
        postgresql-client \
        sqlite

COPY --from=downloader /runtime/ /schemas/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
