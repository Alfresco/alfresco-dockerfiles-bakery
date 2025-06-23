#!/bin/bash

/home/alfresco/set-config.sh
exec catalina.sh run "$@"
