#!/bin/bash

$ACTIVITI_CONFIG_DIR/set-config.sh
exec catalina.sh run "$@"
