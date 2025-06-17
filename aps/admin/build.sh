#!/bin/bash

# Move to script directory
cd $(dirname $0)

# Globals
declare tag=${1:-1.11.0}

# Check docker is installed
# Not totally necessary. Neither is the
check_for_docker () {
    local docker_test=''

    if [[ -n $BASH_VERSINFO && ( $BASH_VERSINFO -ge 4 ) ]]
    then
        docker_test='docker &>> /dev/null'
    else
        # bash 3.x and below. Thank you Apple.
        docker_test='docker >> /dev/null 2>&1'
    fi

    eval ${docker_test}
    local retval=$?
    if [ ${retval} -ne 0 ]
    then
        echo 'No docker found'
        exit ${retval}
    fi
}

check_war_file () {
  local file='activiti-admin.war'
  local file_path=$(find ../.. -type f -name $file | head -1)
  if [ ! -z $file_path ]; then
    echo "Found '$file' in '$file_path' directory"

    local new_file_path='target/war/activiti-admin'
    mkdir -p $new_file_path
    echo "Created new directory '$new_file_path' in '$(dirname $0)'"

    echo "Unzipping '$file' in '$new_file_path'"
    unzip -q -o $file_path -d $new_file_path
  else
    echo "Could not find '$file'. Downloading Activiti Admin version $tag from Nexus"
    mvn clean package -Dactiviti-admin.version=${tag}
  fi
}

check_for_docker
check_war_file

echo "Building docker image for Activiti Admin..."
docker build --no-cache -t process-services-admin:${tag} .
