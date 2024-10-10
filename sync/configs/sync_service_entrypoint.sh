#!/bin/bash

# Check the existance of a custom configuration
CUSTOM_CONFIG_FOLDER="custom_config"

# custom config files
declare -a arr=("config.yml"
                "sync.p12"
                "sync.truststore"
                "jmx.access"
                "jmx.password"
                "syncservice.sh")

check_file(){
    if [ -f ${CUSTOM_CONFIG_FOLDER}/$1 ]
    then
        echo "  copy $1"
        cp -f ${CUSTOM_CONFIG_FOLDER}/$1 .
    else
        echo "  no custom $1 found ..."
    fi
}

# loop through allowed custom file names
for i in "${arr[@]}"
do
    echo "search $i ..."
    check_file $i
done

chmod -R +x .

source update-syncservice.sh .
source ${SYNC_SERVICE_FOLDER}/syncservice.sh ${1}
