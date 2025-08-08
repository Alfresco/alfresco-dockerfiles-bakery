#!/bin/sh
set -e

if [[ $REPO_HOST == "" ]]; then
    REPO_HOST=localhost
fi

if [[ $REPO_PORT == "" ]]; then
    REPO_PORT=8080
fi

if [[ $USE_SSL == "true" ]]; then
    sed -ie 's_port="8080"_port="8080" scheme="https"_' "$CATALINA_HOME"/conf/server.xml
fi

echo "Replace 'REPO_HOST' with '$REPO_HOST' and 'REPO_PORT' with '$REPO_PORT'"

xmlstarlet ed --inplace \
-u "/alfresco-config/config[@evaluator='string-compare' and @condition='DocumentLibrary']/repository-url" -v "http://"$REPO_HOST:$REPO_PORT"/alfresco" \
-u "/alfresco-config/config[@evaluator='string-compare' and @condition='Remote']/remote/endpoint/endpoint-url" -v "http://"$REPO_HOST:$REPO_PORT"/alfresco/s" \
-u "/alfresco-config/config[@evaluator='string-compare' and @condition='Remote']/remote/endpoint[id='alfresco-api']/endpoint-url" -v "http://"$REPO_HOST:$REPO_PORT"/alfresco/api" \
"$CATALINA_HOME"/shared/classes/alfresco/web-extension/share-config-custom.xml

echo "NEW -csrf.filter.referer is '$CSRF_FILTER_REFERER'"
echo "NEW -csrf.filter.origin is '$CSRF_FILTER_ORIGIN'"

if [ "${CSRF_FILTER_REFERER}" != "" ] && [  "${CSRF_FILTER_ORIGIN}" != "" ]; then
    # set CSRFPolicy to true and set both properties referer and origin
    xmlstarlet ed --inplace \
    -u "//config[@evaluator='string-compare' and @condition='CSRFPolicy']/@replace" -v "true" \
    -u "//config[@evaluator='string-compare' and @condition='CSRFPolicy']//referer" -v "$CSRF_FILTER_REFERER" \
    -u "//config[@evaluator='string-compare' and @condition='CSRFPolicy']//origin" -v "$CSRF_FILTER_ORIGIN" \
    "$CATALINA_HOME"/shared/classes/alfresco/web-extension/share-config-custom.xml
fi

exec catalina.sh run
