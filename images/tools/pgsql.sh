#!/bin/bash

setup_pgsql () {
    : > ~/.pgpass
    : > ~/.pg_service.conf

	PGPASSWORD=$(cat $POSTGRES_PASSWORD_FILE)
	cat > ~/.pgpass <<EOF
${PGHOST}:5432:template1:${PGUSER}:${PGPASSWORD}
${PGHOST}:5432:${PGUSER}:${PGUSER}:${PGPASSWORD}
${PGHOST}:5432:${POSTGRES_DB}:${PGUSER}:${PGPASSWORD}
EOF

    cat > ~/.pg_service.conf <<EOF
[swh]
dbname=${POSTGRES_DB}
host=${PGHOST}
port=5432
user=${PGUSER}
EOF
    chmod 0600 ~/.pgpass
	echo "DONE setup Postgresql client config file"
	echo "cat ~/.pg_service.conf"
	cat ~/.pg_service.conf
}

wait_pgsql () {
    local db_to_check
    if [ $# -ge 1 ]; then
        db_to_check="$1"
    else
        db_to_check=$POSTGRES_DB
    fi

    if [ $# -ge 2 ]; then
        host_to_check="$2"
    else
        host_to_check=$PGHOST
    fi

    echo Waiting for postgresql to start on $host_to_check and for database $db_to_check to be available.
    wait-for-it ${host_to_check}:5432 -s --timeout=0
    until psql "dbname=${db_to_check} port=5432 host=${host_to_check} user=${PGUSER}" -c "select 'postgresql is up!' as connected"; do sleep 1; done
}

check_pgsql_db_created () {
    psql "dbname=${POSTGRES_DB} port=5432 host=${PGHOST} user=${PGUSER}" -c "select 'postgresql is up!' as connected" >/dev/null 2>/dev/null
}
