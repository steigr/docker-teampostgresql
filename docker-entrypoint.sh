#!/usr/bin/env bash

set -eo pipefail
# [[ -z "$TRACE" ]] || set -x

vars() {
	export CADDY_PORT=${CADDY_PORT:-$PORT}
	export CADDY_PORT=${CADDY_PORT:-80}
	export TEAMPOSTGRESQL_PORT=${TEAMPOSTGRESQL_PORT:-8082}
	export TEAMPOSTGRESQL_ADMIN_USER=${TEAMPOSTGRESQL_ADMIN_USER:-}
	export TEAMPOSTGRESQL_ADMIN_PASSWORD=${TEAMPOSTGRESQL_ADMIN_PASSWORD:-$TEAMPOSTGRESQL_ADMIN_USER}

	if [[ "$TEAMPOSTGRESQL_ADMIN_USER" ]]; then
		export TEAMPOSTGRESQL_ANONYMOUS_ACCESS=${TEAMPOSTGRESQL_ANONYMOUS_ACCESS:-10}
	else
		export TEAMPOSTGRESQL_ANONYMOUS_ACCESS=${TEAMPOSTGRESQL_ANONYMOUS_ACCESS:-40}
	fi

	export TEAMPOSTGRESQL_COOKIES_ENABLED=${TEAMPOSTGRESQL_COOKIES_ENABLED:-true}
	export TEAMPOSTGRESQL_DATA_DIRECTORY=${TEAMPOSTGRESQL_DATA_DIRECTORY:-/tmp}
	export TEAMPOSTGRESQL_HTTPS=${TEAMPOSTGRESQL_HTTPS:-DISABLED}

	# Further variables:
	# TEAMPOSTGRESQL_DEFAULT_HOST
	# TEAMPOSTGRESQL_DEFAULT_PORT
	# TEAMPOSTGRESQL_DEFAULT_USERNAME
	# TEAMPOSTGRESQL_DEFAULT_PASSWORD
	# TEAMPOSTGRESQL_DEFAULT_DATABASENAME
	# TEAMPOSTGRESQL_DEFAULT_SSL

	if [[ "$TEAMPOSTGRESQL_DEFAULT_HOST" ]]; then
		export TEAMPOSTGRESQL_DEFAULT_PORT=${TEAMPOSTGRESQL_DEFAULT_PORT:-5432}
		export TEAMPOSTGRESQL_DEFAULT_USERNAME=${TEAMPOSTGRESQL_DEFAULT_USERNAME:-postgres}
		export TEAMPOSTGRESQL_DEFAULT_PASSWORD=${TEAMPOSTGRESQL_DEFAULT_PASSWORD:-postgres}
		export TEAMPOSTGRESQL_DEFAULT_DATABASENAME=${TEAMPOSTGRESQL_DEFAULT_DATABASENAME:-postgres}
		export TEAMPOSTGRESQL_DEFAULT_SSL=${TEAMPOSTGRESQL_DEFAULT_SSL:-false}
	fi
}

main() {
	command -v "$1" >/dev/null 2>&1 && exec "$@"
	cd /app
	update_teampostgresql_config | tee "$PWD/WEB-INF/teampostgresql-config.xml" | debug_logger
	update_caddy_config          | tee "$PWD/Caddyfile" | debug_logger
	env - $(command -v su-exec) teampostgresql $(command -v caddy) -log=stdout -conf="$PWD/Caddyfile" -root=/var/tmp "$@" <>/dev/null 2>&1 &
	set -- env - $(command -v su-exec) teampostgresql $(command -v java) -cp /app/WEB-INF/lib/log4j-1.2.17.jar-1.0.jar:/app/WEB-INF/classes:/app/WEB-INF/lib/* dbexplorer.TeamPostgreSQL $TEAMPOSTGRESQL_PORT . /
	environment_hygiene
	exec "$@"
}

debug_logger() {
	[[ "$TRACE" ]] && cat || true
}

environment_hygiene() {
	# clear unneeded environment variables
	for var in $(printenv | cut -f1 -d= | grep -v -e '^HOME$' -e '^USER$' -e '^PATH$'); do unset $var; done
	# see https://blog.packagecloud.io/eng/2017/02/21/set-environment-variable-save-thousands-of-system-calls/
	export TZ=:/etc/localtime
	# set language and sorting
	export LANG=${LANG:-C.UTF-8} LC_ALL=${LC_ALL:-C.UTF-8}
}
update_caddy_config() {
	cat<<update_caddy_config
0.0.0.0:${CADDY_PORT}
proxy / 127.0.0.1:${TEAMPOSTGRESQL_PORT} {
	transparent
}
update_caddy_config
}

update_teampostgresql_config() {
	cat<<update_teampostgresql_config
<?xml version="1.0" encoding="UTF-8"?>
<config>
	<adminuser>$TEAMPOSTGRESQL_ADMIN_USER</adminuser>
	<adminuserpassword>$TEAMPOSTGRESQL_ADMIN_PASSWORD</adminuserpassword>
	<anonymousaccess>$TEAMPOSTGRESQL_ANONYMOUS_ACCESS</anonymousaccess>
	<anonymousprofile>$TEAMPOSTGRESQL_ANONYMOUS_PROFILE</anonymousprofile>
	<cookiesenabled>$TEAMPOSTGRESQL_COOKIES_ENABLED</cookiesenabled>
	<datadirectory>$TEAMPOSTGRESQL_DATA_DIRECTORY</datadirectory>
	<https>$TEAMPOSTGRESQL_HTTPS</https>
update_teampostgresql_config
if printenv | grep -q "^TEAMPOSTGRESQL_DEFAULT_"; then
	cat<<update_teampostgresql_config
	<defaultdatabase>
update_teampostgresql_config
	printenv | grep "^TEAMPOSTGRESQL_DEFAULT_" | cut -f3- -d_ | while read var; do
	  val="${var#*=}"
	  var="${var%%=*}"
	  var="$(echo $var | sed -e 's/_/-/g' | tr '[:upper:]' '[:lower:]')"
	  echo "<$var>$val</$var>"
	done
	cat<<update_teampostgresql_config
	</defaultdatabase>
update_teampostgresql_config
fi
	cat<<update_teampostgresql_config
</config>
update_teampostgresql_config
}

with_reaper() {
	if pidof tini >/dev/null 2>&1; then
		source /.env && rm /.env
		[[ -z "$TRACE" ]] || set -x
	else
		printenv | sed -e 's/^/export /' -e 's/=/="/' -e 's/$/"/' > /.env
		exec env - sh -c "exec $(command -v tini) $0 $@"
	fi
}

with_reaper "$@"
vars
main "$@"