FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS downloader
ARG PDNS_AUTH_VERSION

WORKDIR /src

RUN apk update \
    && apk add --no-cache wget \
    && wget "https://downloads.powerdns.com/releases/pdns-${PDNS_AUTH_VERSION}.tar.bz2" \
    && tar xf pdns-${PDNS_AUTH_VERSION}.tar.bz2

WORKDIR /src/pdns-${PDNS_AUTH_VERSION}

RUN mkdir /runtime \
    && find . -type f -name "schema.*.sql" -exec cp {} /runtime/ \;

FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS runtime

RUN apk update \
    && apk add --no-cache \
        mariadb-client \
        postgresql-client \
        sqlite

COPY --from=downloader /runtime/ /schemas/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
