#!/bin/bash

set -e

source /srv/softwareheritage/utils/pgsql.sh

# generate the config file from the 'template'
if [ -f /etc/softwareheritage/config.yml.tmpl ]; then
	# I know... I know!
	eval "echo \"`cat /etc/softwareheritage/config.yml.tmpl`\"" > \
		 /etc/softwareheritage/config.yml
fi

# generate the pgservice file if any
if [ -f /run/secrets/postgres-password ]; then
    POSTGRES_PASSWORD_FILE=/run/secrets/postgres-password
    setup_pgsql
fi

# For debugging purpose
echo "### CONFIG FILE ###"
cat /etc/softwareheritage/config.yml | grep -v password
echo "###################"

echo "Arguments: $@"

case "$1" in
    "shell")
      exec bash -i
      ;;
    *)
      if [ -v POSTGRES_DB ]; then
        wait_pgsql template1

        echo Database setup
        if ! check_pgsql_db_created; then
          echo Creating database and extensions...
          swh db create --db-name ${POSTGRES_DB} $1
        fi
        echo Initializing the database...
        swh db init-admin --db-name ${POSTGRES_DB} $1
        swh db init --flavor ${FLAVOR:-default} $1
        swh db upgrade $1
      fi

      echo "Starting the SWH $1 RPC server"
      exec gunicorn3 \
           --bind 0.0.0.0:${PORT:-5000} \
           --bind unix:/var/run/gunicorn/swh/$1.sock \
           --threads ${GUNICORN_THREADS:-4} \
           --workers ${GUNICORN_WORKERS:-16} \
           --log-level "${LOG_LEVEL:-WARNING}" \
           --timeout ${GUNICORN_TIMEOUT:-3600} \
           --statsd-host=prometheus-statsd-exporter:9125 \
           --statsd-prefix=service.app.$1  \
           "swh.$1.api.server:make_app_from_configfile()"
      ;;
esac
