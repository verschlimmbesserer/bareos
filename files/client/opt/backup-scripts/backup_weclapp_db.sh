#!/usr/bin/env bash

backup_dir="/opt/backups/weclapp"
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

function create_backup_dir() {
    if [[ ! -d ${1} ]]; then
        mkdir -p ${backup_dir}/${1}
    fi
}

function get_postgres_images() {
    grep -hr "image: postgres" --exclude-dir=$SCRIPTPATH /opt/* | cut -d ":" -f 2- | sort| uniq
}

function get_postgres_container() {
    /usr/bin/docker ps  --filter ancestor=${1} --format "{{.Names}}"
}

function backup_postgres() {
    /usr/bin/docker exec ${2} su -c "pg_dump --clean --if-exists postgres" postgres | /usr/bin/gzip > ${1}/${2}/${2}.gz
}

function main() {
    for db_image in $(get_postgres_images) ; do
        echo "found postgres container with ${db_image}"
        for instance in $(get_postgres_container ${db_image}); do
          create_backup_dir ${instance}
          echo "start backup for instance ${instance}"
          backup_postgres ${backup_dir} ${instance} &
        done
        echo "wait for backups to finish"
        wait
        echo "backup finished"
    done
}

main