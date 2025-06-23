#!/bin/bash

./set-config.sh
exec catalina.sh run "$@"
