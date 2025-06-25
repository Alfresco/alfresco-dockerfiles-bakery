#!/bin/bash

if [ -f "$ACTIVITI_ADMIN_PROPS" ] && [ -s "$ACTIVITI_ADMIN_PROPS" ]; then
    echo "Properties file already exists and is not empty at $ACTIVITI_ADMIN_PROPS - using mounted configuration"
else
    echo "Generating properties file using environment variables and defaults"

    # Set defaults (only if not already set) and export them for envsubst
    export ACTIVITI_ADMIN_DATASOURCE_URL="${ACTIVITI_ADMIN_DATASOURCE_URL:-jdbc:h2:mem:activiti_admin;DB_CLOSE_DELAY=1000}"
    export ACTIVITI_ADMIN_DATASOURCE_DRIVER="${ACTIVITI_ADMIN_DATASOURCE_DRIVER:-org.h2.Driver}"
    export ACTIVITI_ADMIN_DATASOURCE_USERNAME="${ACTIVITI_ADMIN_DATASOURCE_USERNAME:-alfresco}"
    export ACTIVITI_ADMIN_DATASOURCE_PASSWORD="${ACTIVITI_ADMIN_DATASOURCE_PASSWORD:-alfresco}"
    export ACTIVITI_ADMIN_HIBERNATE_DIALECT="${ACTIVITI_ADMIN_HIBERNATE_DIALECT:-org.hibernate.dialect.H2Dialect}"

    export ACTIVITI_ADMIN_REST_APP_HOST="${ACTIVITI_ADMIN_REST_APP_HOST:-http://localhost}"
    export ACTIVITI_ADMIN_REST_APP_PORT="${ACTIVITI_ADMIN_REST_APP_PORT:-8080}"
    export ACTIVITI_ADMIN_REST_APP_USERNAME="${ACTIVITI_ADMIN_REST_APP_USERNAME:-admin@app.activiti.com}"
    export ACTIVITI_ADMIN_REST_APP_PASSWORD="${ACTIVITI_ADMIN_REST_APP_PASSWORD:-admin}"
    export ACTIVITI_ADMIN_REST_APP_AUTHTYPE="${ACTIVITI_ADMIN_REST_APP_AUTHTYPE:-basic}"

    export ACTIVITI_ADMIN_REST_APP_SSO_ENABLED="${ACTIVITI_ADMIN_REST_APP_SSO_ENABLED:-true}"
    export ACTIVITI_ADMIN_REST_APP_SSO_AUTH_SERVER_URL="${ACTIVITI_ADMIN_REST_APP_SSO_AUTH_SERVER_URL:-https://acadev.envalfresco.com/auth}"
    export ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_ID="${ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_ID:-alfresco}"
    export ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_SECRET="${ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_SECRET:-}"
    export ACTIVITI_ADMIN_REST_APP_SSO_REALM="${ACTIVITI_ADMIN_REST_APP_SSO_REALM:-alfresco}"
    export ACTIVITI_ADMIN_REST_APP_SSO_SCOPE="${ACTIVITI_ADMIN_REST_APP_SSO_SCOPE:-offline_access}"
    export ACTIVITI_ADMIN_REST_APP_SSO_AUTH_URI="${ACTIVITI_ADMIN_REST_APP_SSO_AUTH_URI:-${ACTIVITI_ADMIN_REST_APP_SSO_AUTH_SERVER_URL}/realms/${ACTIVITI_ADMIN_REST_APP_SSO_REALM}/protocol/openid-connect/auth}"
    export ACTIVITI_ADMIN_REST_APP_SSO_TOKEN_URI="${ACTIVITI_ADMIN_REST_APP_SSO_TOKEN_URI:-${ACTIVITI_ADMIN_REST_APP_SSO_AUTH_SERVER_URL}/realms/${ACTIVITI_ADMIN_REST_APP_SSO_REALM}/protocol/openid-connect/token}"
    export ACTIVITI_ADMIN_REST_APP_SSO_REDIRECT_URI="${ACTIVITI_ADMIN_REST_APP_SSO_REDIRECT_URI:-http://localhost:8081/activiti-admin/app/rest/integration/sso/confirm-auth-request}"

    # Process template with envsubst
    if [ -f "$ACTIVITI_ADMIN_PROPS_TEMPLATE" ]; then
        echo "Processing template: $ACTIVITI_ADMIN_PROPS_TEMPLATE -> $ACTIVITI_ADMIN_PROPS"
        envsubst < "$ACTIVITI_ADMIN_PROPS_TEMPLATE" > "$ACTIVITI_ADMIN_PROPS"
    else
        echo "ERROR: Template file not found: $ACTIVITI_ADMIN_PROPS_TEMPLATE"
        exit 1
    fi
fi

exec catalina.sh run "$@"
