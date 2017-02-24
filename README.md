# TeamPostgreSQL Container

[![](https://images.microbadger.com/badges/image/steigr/teampostgresql.svg)](http://microbadger.com/images/steigr/teampostgresql "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/steigr/teampostgresql.svg)](http://microbadger.com/images/steigr/teampostgresql "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/steigr/teampostgresql.svg)](http://microbadger.com/images/steigr/teampostgresql "Get your own commit badge on microbadger.com")

- Based on [alpinelinux with Oracle JRE](http://hub.docker.com/r/anapsix/alpine-java)
- Use [Caddy](https://github.com/mholt/caddy) as HTTP/2 reverse proxy


## Configuration

### Caddy
* `$CADDY_PORT` or `$PORT` (default: `80`)

### TeamPostgreSQL
* `$TEAMPOSTGRESQL_PORT` (default: `8082`)
* `$TEAMPOSTGRESQL_ADMIN_USER` (default: unset)
* `$TEAMPOSTGRESQL_ADMIN_PASSWORD` (default: `$TEAMPOSTGRESQL_ADMIN_USER`)
* `$TEAMPOSTGRESQL_ANONYMOUS_ACCESS` (default `40` or `10` if `$TEAMPOSTGRESQL_ADMIN_USER` is set )
* `$TEAMPOSTGRESQL_COOKIES_ENABLED` (default: `true`)
* `$TEAMPOSTGRESQL_DATA_DIRECTORY` (default: `/tmp`)
* `$TEAMPOSTGRESQL_HTTPS` (default: `DISABLED`)
* `$TEAMPOSTGRESQL_DEFAULT_HOST` (default: unset)
* `$TEAMPOSTGRESQL_DEFAULT_PORT` (default: `5432`)
* `$TEAMPOSTGRESQL_DEFAULT_USERNAME` (default: `postgres`)
* `$TEAMPOSTGRESQL_DEFAULT_PASSWORD` (default: `postgres`)
* `$TEAMPOSTGRESQL_DEFAULT_DATABASENAME` (default: `postgres`)
* `$TEAMPOSTGRESQL_DEFAULT_SSL` (default: `false`)


## Example

```shell
# launch postgres server
docker run --detach=true \
           --env=POSTGRESQL_PASSWORD=supersecure \
           --name=postgres \
           postgres
# launch teampostgresql web application
docker run --rm --link=postgres \
           --publish=8432:80 \
           --name=teampostgresql \
           --env=TEAMPOSTGRESQL_ADMIN_USER=postgres \
           --env=TEAMPOSTGRESQL_ADMIN_PASSWORD=supersecure \
           --env=TEAMPOSTGRESQL_DEFAULT_HOST=postgres \
           steigr/teampostgresql
```