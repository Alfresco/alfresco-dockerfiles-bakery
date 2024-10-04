#!/bin/sh

set -e

# ROOT

APP_CONFIG_FILE="${NGINX_ENVSUBST_OUTPUT_DIR}/app.config.json"

if [ -n "${APP_CONFIG_AUTH_TYPE}" ]; then
  echo "SET APP_CONFIG_AUTH_TYPE"
  sed -e "s/\"authType\": \".*\"/\"authType\": \"${APP_CONFIG_AUTH_TYPE}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PROVIDER}" ]; then
  echo "SET APP_CONFIG_PROVIDER"
  sed -e "s/\"providers\": \".*\"/\"providers\": \"${APP_CONFIG_PROVIDER}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_IDENTITY_HOST}" ]; then
  echo "SET APP_CONFIG_IDENTITY_HOST"
  replace="\/"
  encodedIdentity=${APP_CONFIG_IDENTITY_HOST//\//$replace}
  sed -e "s/\"identityHost\": \".*\"/\"identityHost\": \"$encodedIdentity\"/g" -i "$APP_CONFIG_FILE"
fi

if [[ -n "${APP_CONFIG_BPM_HOST}" ]]; then
  echo "SET APP_CONFIG_BPM_HOST"
  replace="\/"
  encoded=${APP_CONFIG_BPM_HOST//\//$replace}
  sed -e "s/\"bpmHost\": \".*\"/\"bpmHost\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [[ -n "${APP_CONFIG_ECM_HOST}" ]]; then
  echo "SET APP_CONFIG_ECM_HOST"
  replace="\/"
  encoded=${APP_CONFIG_ECM_HOST//\//$replace}
  sed -e "s/\"ecmHost\": \".*\"/\"ecmHost\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_BASE_SHARE_URL}" ]; then
  echo "SET APP_BASE_SHARE_URL"
  replace="\/"
  encoded=${APP_BASE_SHARE_URL//\//$replace}
  sed -e "s/\"baseShareUrl\": \".*\"/\"baseShareUrl\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

# OAUTH2

if [ -n "${APP_CONFIG_OAUTH2_HOST}" ]; then
  echo "SET APP_CONFIG_OAUTH2_HOST"
  replace="\/"
  encoded=${APP_CONFIG_OAUTH2_HOST//\//$replace}
  sed -e "s/\"host\": \".*\"/\"host\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_CLIENTID}" ]; then
  echo "SET APP_CONFIG_OAUTH2_CLIENTID"
  sed -e "s/\"clientId\": \".*\"/\"clientId\": \"${APP_CONFIG_OAUTH2_CLIENTID}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_CLIENT_SECRET}" ]; then
  echo "SET APP_CONFIG_OAUTH2_CLIENT_SECRET"
  sed -e "s/\"secret\": \".*\"/\"secret\": \"${APP_CONFIG_OAUTH2_CLIENT_SECRET}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_IMPLICIT_FLOW}" ]; then
  echo "SET APP_CONFIG_OAUTH2_IMPLICIT_FLOW"
  sed -e "s/\"implicitFlow\": [^,]*/\"implicitFlow\": ${APP_CONFIG_OAUTH2_IMPLICIT_FLOW}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_CODE_FLOW}" ]; then
  echo "SET APP_CONFIG_OAUTH2_CODE_FLOW"
  sed -e "s/\"codeFlow\": [^,]*/\"codeFlow\": ${APP_CONFIG_OAUTH2_CODE_FLOW}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_LOGOUT_URL}" ]; then
  echo "SET APP_CONFIG_OAUTH2_LOGOUT_URL"
  replace="\/"
  encoded=${APP_CONFIG_OAUTH2_LOGOUT_URL//\//$replace}
  sed -e "s/\"logoutUrl\": [^,]*/\"logoutUrl\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_LOGOUT_PARAMETERS}" ]; then
  echo "SET APP_CONFIG_OAUTH2_LOGOUT_PARAMETERS"
  sed -i "s/\"logoutParameters\": \[.*\]/\"logoutParameters\": [${APP_CONFIG_OAUTH2_LOGOUT_PARAMETERS}]/" "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_SCOPE}" ]; then
  echo "SET APP_CONFIG_OAUTH2_SCOPE"
  sed -e "s/\"scope\": [^,]*/\"scope\": ${APP_CONFIG_OAUTH2_SCOPE}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_AUDIENCE}" ]; then
  echo "SET APP_CONFIG_OAUTH2_AUDIENCE"
  replace="\/"
  encoded=${APP_CONFIG_OAUTH2_AUDIENCE//\//$replace}
  sed -e "s/\"audience\": [^,]*/\"audience\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_SILENT_LOGIN}" ]; then
  echo "SET APP_CONFIG_OAUTH2_SILENT_LOGIN"
  sed -e "s/\"silentLogin\": [^,]*/\"silentLogin\": ${APP_CONFIG_OAUTH2_SILENT_LOGIN}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_REDIRECT_SILENT_IFRAME_URI}" ]; then
  echo "SET APP_CONFIG_OAUTH2_REDIRECT_SILENT_IFRAME_URI"
  replace="\/"
  encoded=${APP_CONFIG_OAUTH2_REDIRECT_SILENT_IFRAME_URI//\//$replace}
  sed -e "s/\"redirectSilentIframeUri\": \".*\"/\"redirectSilentIframeUri\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_REDIRECT_LOGIN}" ]; then
  echo "SET APP_CONFIG_OAUTH2_REDIRECT_LOGIN"
  replace="\/"
  encoded=${APP_CONFIG_OAUTH2_REDIRECT_LOGIN//\//$replace}
  sed -e "s/\"redirectUri\": \".*\"/\"redirectUri\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_OAUTH2_REDIRECT_LOGOUT}" ]; then
  echo "SET APP_CONFIG_OAUTH2_REDIRECT_LOGOUT"
  replace="\/"
  encoded=${APP_CONFIG_OAUTH2_REDIRECT_LOGOUT//\//$replace}
  sed -e "s/\"redirectUriLogout\": \".*\"/\"redirectUriLogout\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi


# MS OFFICE365

if [ -n "${APP_CONFIG_MICROSOFT_ONLINE_OOI_URL}" ]; then
  echo "SET APP_CONFIG_MICROSOFT_ONLINE_OOI_URL"
  replace="\/"
  encoded=${APP_CONFIG_MICROSOFT_ONLINE_OOI_URL//\//$replace}
  sed -e "s/\"msHost\": \".*\"/\"msHost\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_MICROSOFT_ONLINE_CLIENTID}" ]; then
  echo "SET APP_CONFIG_MICROSOFT_ONLINE_CLIENTID"
  sed -e "s/\"msClientId\": \".*\"/\"msClientId\": \"${APP_CONFIG_MICROSOFT_ONLINE_CLIENTID}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_MICROSOFT_ONLINE_AUTHORITY}" ]; then
  echo "SET APP_CONFIG_MICROSOFT_ONLINE_AUTHORITY"
  replace="\/"
  encoded=${APP_CONFIG_MICROSOFT_ONLINE_AUTHORITY//\//$replace}
  sed -e "s/\"msAuthority\": \".*\"/\"msAuthority\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_MICROSOFT_ONLINE_REDIRECT}" ]; then
  echo "SET APP_CONFIG_MICROSOFT_ONLINE_REDIRECT"
  replace="\/"
  encoded=${APP_CONFIG_MICROSOFT_ONLINE_REDIRECT//\//$replace}
  sed -e "s/\"msRedirectUri\": \".*\"/\"msRedirectUri\": \"${encoded}\"/g" -i "$APP_CONFIG_FILE"
fi

# PLUGINS

if [ -n "${APP_CONFIG_PLUGIN_MICROSOFT_ONLINE}" ]; then
  echo "SET APP_CONFIG_PLUGIN_MICROSOFT_ONLINE"
  sed -e "s/\"microsoftOnline\": [^,]*/\"microsoftOnline\": ${APP_CONFIG_PLUGIN_MICROSOFT_ONLINE}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_AOS}" ]; then
  echo "SET APP_CONFIG_PLUGIN_AOS"
  sed -e "s/\"aosPlugin\": [^,]*/\"aosPlugin\": ${APP_CONFIG_PLUGIN_AOS}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_CONTENT_SERVICE}" ]; then
  echo "SET APP_CONFIG_PLUGIN_CONTENT_SERVICE"
  sed -e "s/\"contentService\": [^,]*/\"contentService\": ${APP_CONFIG_PLUGIN_CONTENT_SERVICE}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_FOLDER_RULES}" ]; then
  echo "SET APP_CONFIG_PLUGIN_FOLDER_RULES"
  sed -e "s/\"folderRules\": [^,]*/\"folderRules\": ${APP_CONFIG_PLUGIN_FOLDER_RULES}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_PROCESS_SERVICE}" ]; then
  echo "SET APP_CONFIG_PLUGIN_PROCESS_SERVICE"
  sed -e "s/\"processService\": [^,]*/\"processService\": ${APP_CONFIG_PLUGIN_PROCESS_SERVICE}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_TAGS}" ]; then
  echo "SET APP_CONFIG_PLUGIN_TAGS"
  sed -e "s/\"tagsEnabled\": [^,]*/\"tagsEnabled\": ${APP_CONFIG_PLUGIN_TAGS}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_CATEGORIES}" ]; then
  echo "SET APP_CONFIG_PLUGIN_CATEGORIES"
  sed -e "s/\"categoriesEnabled\": [^,]*/\"categoriesEnabled\": ${APP_CONFIG_PLUGIN_CATEGORIES}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_LEGAL_HOLD}" ]; then
  echo "SET APP_CONFIG_PLUGIN_LEGAL_HOLD"
  sed -e "s/\"legalHoldEnabled\": [^,]*/\"legalHoldEnabled\": ${APP_CONFIG_PLUGIN_LEGAL_HOLD}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_PLUGIN_KNOWLEDGE_RETRIEVAL}" ]; then
  echo "SET APP_CONFIG_PLUGIN_KNOWLEDGE_RETRIEVAL"
  sed -e "s/\"knowledgeRetrievalEnabled\": [^,]*/\"knowledgeRetrievalEnabled\": ${APP_CONFIG_PLUGIN_KNOWLEDGE_RETRIEVAL}/g" -i "$APP_CONFIG_FILE"
fi

# PENDO

if [ -n "${APP_CONFIG_ANALYTICS_PENDO_ENABLED}" ]; then
  echo "SET APP_CONFIG_ANALYTICS_PENDO_ENABLED"
  sed -e "s/\"pendoEnabled\": [^,]*/\"pendoEnabled\": ${APP_CONFIG_ANALYTICS_PENDO_ENABLED}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_ANALYTICS_PENDO_KEY}" ]; then
  echo "SET APP_CONFIG_ANALYTICS_PENDO_KEY"
  sed -e "s/\"pendoKey\": [^,]*/\"pendoKey\": ${APP_CONFIG_ANALYTICS_PENDO_KEY}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_ANALYTICS_PENDO_EXCLUDE_ALL_TEXT}" ]; then
  echo "SET APP_CONFIG_ANALYTICS_PENDO_EXCLUDE_ALL_TEXT"
  sed -e "s/\"pendoExcludeAllText\": [^,]*/\"pendoExcludeAllText\": ${APP_CONFIG_ANALYTICS_PENDO_EXCLUDE_ALL_TEXT}/g" -i "$APP_CONFIG_FILE"
fi

if [ -n "${APP_CONFIG_CUSTOMER_NAME}" ]; then
  echo "SET APP_CONFIG_CUSTOMER_NAME"
  sed -e "s/\"pendoCustomerName\": [^,]*/\"pendoCustomerName\": ${APP_CONFIG_CUSTOMER_NAME}/g" -i "$APP_CONFIG_FILE"
fi
