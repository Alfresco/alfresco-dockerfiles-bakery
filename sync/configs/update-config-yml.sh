#!/bin/bash

CONFIG_YML_PATH=${1}

#general settings to point to the docker activemq, alfresco, postgres
sed -i 's/hostname: localhost/hostname: alfresco/' $CONFIG_YML_PATH
sed -i 's/host: localhost/host: activemq/' $CONFIG_YML_PATH
sed -i 's/url: jdbc:postgresql:alfresco/url: jdbc:postgresql:\/\/postgres:5432\/alfresco/' $CONFIG_YML_PATH

sed -i 's/brokerName=localhost/brokerName=activemq/' $CONFIG_YML_PATH
