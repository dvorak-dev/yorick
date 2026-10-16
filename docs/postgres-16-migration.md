# PostgreSQL 15 to 16 — production cutover

The repo already points at Postgres 16 (`postgres:16-alpine`, release 16.15) and the `pg` gem 1.7.0. Production data is still a Postgres 15 directory. Changing only the image tag does not upgrade that directory. Postgres 16 exits when `PG_VERSION` in the data directory is 15, and it does not delete the files.

Do this on the server, in the directory that holds the live Compose file. Do not run `docker compose down -v`. Do not delete `postgres_data` or `elasticsearch_data`.

## What the live Compose file should look like

[docker-compose.prod.yml](../docker-compose.prod.yml) is the target. Compared with the current live copy, two image lines differ:

- `db` image: `postgres:15-alpine` becomes `postgres:16-alpine`
- `elasticsearch` image: `docker.elastic.co/elasticsearch/elasticsearch:8.19.23` (the live copy still shows `8.13.4` if that line was not updated on the server)

Leave every other service as it is: web `ghcr.io/dvorak-dev/yorick:latest`, MCP `ghcr.io/dvorak-dev/yorick-mcp:main`, health checks, network, and DNS.

The `db` volume is the exception during the cutover. Keep the existing `postgres_data` volume on disk and mount a new empty volume:

```yaml
  db:
    image: postgres:16-alpine
    container_name: yorick-db
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - postgres_data_pg16:/var/lib/postgresql/data
    networks:
      - yorick-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-yorick} -d ${POSTGRES_DB:-yorick}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:          # Postgres 15 files. Leave this in place.
    driver: local
  postgres_data_pg16:     # Postgres 16 data, restored from the dump.
    driver: local
  elasticsearch_data:
    driver: local
  yorick_storage:
    driver: local
  yorick_logs:
    driver: local
```

After `postgres_data_pg16` is in use and the old volume is no longer needed, delete `postgres_data` by hand. Until then, do not point `postgres:16-alpine` at `postgres_data`.

## Cutover

Web and the MCP server lose the database from the moment `db` stops until the restore finishes. Leave Elasticsearch running.

1. Confirm the running server is still 15. The command prints `15`.

   ```bash
   docker compose exec db cat /var/lib/postgresql/data/PG_VERSION
   ```

2. Read `POSTGRES_USER` and `POSTGRES_DB` from `.env`. The health check falls back to `yorick` / `yorick` when those variables are unset.

3. Dump while that 15 container is still running. `pg_dumpall` is the full backup. The single-database dump is what you restore, because the 16 image creates the role and database from `.env` on first start and a full dump then fails on `CREATE ROLE` / `CREATE DATABASE`.

   ```bash
   docker compose exec -T db pg_dumpall -U "$POSTGRES_USER" > "pg15-all-$(date +%F).sql"
   docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner --no-acl > "pg15-$(date +%F).sql"
   ```

4. Stop only the database:

   ```bash
   docker compose stop db
   ```

5. Edit the live Compose file as shown above, then start only the database so Elasticsearch is not recreated:

   ```bash
   docker compose up -d db
   docker compose exec db cat /var/lib/postgresql/data/PG_VERSION
   ```

   The version file must read `16`. If the container exits, it is mounted on the 15 directory. Point it at `postgres_data_pg16` and start it again. Do not delete the old volume.

6. Restore the application dump into the database the new server created:

   ```bash
   docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "pg15-$(date +%F).sql"
   docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\dt'
   ```

7. Start web and the MCP server again:

   ```bash
   docker compose up -d web mcp-server
   ```

8. Confirm `http://localhost:3000/up` returns success and a known table has its expected row count. Keep `postgres_data` until that check passes.
