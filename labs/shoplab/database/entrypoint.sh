#!/bin/sh
set -eu

data=/var/lib/postgresql/data
mkdir -p "$data" /run/postgresql
chown -R postgres:postgres "$data" /run/postgresql

if [ ! -s "$data/PG_VERSION" ]; then
  su-exec postgres initdb -D "$data" --auth-local=trust --auth-host=scram-sha-256 >/dev/null
  printf "listen_addresses = '*'\npassword_encryption = 'scram-sha-256'\n" >> "$data/postgresql.conf"
  # The isolated Compose subnet is assigned dynamically. Permit password-authenticated
  # clients on that private network; no database port is published to the host.
  printf "host all all all scram-sha-256\n" >> "$data/pg_hba.conf"
  su-exec postgres pg_ctl -D "$data" -w start >/dev/null
  su-exec postgres psql --set=ON_ERROR_STOP=1 --dbname=postgres <<'SQL'
CREATE ROLE websec LOGIN PASSWORD 'local-training-only';
CREATE DATABASE websec OWNER websec;
SQL
  su-exec postgres pg_ctl -D "$data" -m fast -w stop >/dev/null
fi

exec su-exec postgres postgres -D "$data"
