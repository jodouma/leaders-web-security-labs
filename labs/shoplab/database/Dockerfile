FROM alpine:3.22

RUN apk add --no-cache postgresql17 postgresql17-client su-exec \
    && mkdir -p /var/lib/postgresql/data /run/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql /run/postgresql

COPY entrypoint.sh /usr/local/bin/websec-postgres-entrypoint
RUN chmod 0755 /usr/local/bin/websec-postgres-entrypoint

VOLUME ["/var/lib/postgresql/data"]
EXPOSE 5432
ENTRYPOINT ["/usr/local/bin/websec-postgres-entrypoint"]
