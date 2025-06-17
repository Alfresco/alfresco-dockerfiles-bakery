#!/bin/sh
echo $HOME
$HOME/set-activiti-admin-config.sh
echo "Running the startup"
/usr/local/tomcat/bin/catalina.sh run
