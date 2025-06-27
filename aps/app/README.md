# Alfresco Process Services App

Sets of variables configurable with your docker image

## Environment variables

```yaml
alfresco-activiti:
  image:
    repository: localhost/alfresco/alfresco-process-services
    tag: latest
  environment:
    JAVA_OPTS:
    ACTIVITI_LICENSE_MULTI_TENANT:
    ACTIVITI_DATASOURCE_URL:
    ACTIVITI_DATASOURCE_DRIVER:
    ACTIVITI_DATASOURCE_USERNAME:
    ACTIVITI_DATASOURCE_PASSWORD:
    ACTIVITI_HIBERNATE_DIALECT:
    ACTIVITI_ADMIN_EMAIL:
    ACTIVITI_ADMIN_PASSWORD_HASH:
    ACTIVITI_ES_SERVER_TYPE:
    ACTIVITI_ES_REST_CLIENT_ADDRESS:
    ACTIVITI_ES_REST_CLIENT_PORT:
    ACTIVITI_ES_REST_CLIENT_SCHEMA:
    ACTIVITI_ES_REST_CLIENT_AUTH_ENABLED:
    ACTIVITI_ES_REST_CLIENT_USERNAME:
    ACTIVITI_ES_REST_CLIENT_PASSWORD:
    ACTIVITI_ES_REST_CLIENT_KEYSTORE:
    ACTIVITI_ES_REST_CLIENT_KEYSTORE_TYPE:
    ACTIVITI_ES_REST_CLIENT_KEYSTORE_PASSWORD:
    ACTIVITI_CORS_ENABLED:
    ACTIVITI_CORS_ALLOWED_ORIGINS:
    ACTIVITI_CORS_ALLOWED_ORIGIN_PATTERNS:
    ACTIVITI_CORS_ALLOWED_METHODS:
    ACTIVITI_CORS_ALLOWED_HEADERS:
    ACTIVITI_CSRF_DISABLED:
    ACTIVITI_REVIEW_WORKFLOWS_ENABLED:
    IDENTITY_SERVICE_ENABLED:
    IDENTITY_SERVICE_REALM:
    IDENTITY_SERVICE_AUTH:
    IDENTITY_SERVICE_RESOURCE:
    IDENTITY_SERVICE_PRINCIPAL_ATTRIBUTE:
    IDENTITY_CREDENTIALS_SECRET:
    IDENTITY_SERVICE_USE_BROWSER_BASED_LOGOUT:
    IDENTITY_SERVICE_CONTENT_SSO_ENABLED:
    IDENTITY_SERVICE_CONTENT_SSO_CLIENT_ID:
    IDENTITY_SERVICE_CONTENT_SSO_CLIENT_SECRET:
    IDENTITY_SERVICE_CONTENT_SSO_REALM:
    IDENTITY_SERVICE_CONTENT_SSO_SCOPE:
    IDENTITY_SERVICE_CONTENT_SSO_AUTH_URI:
    IDENTITY_SERVICE_CONTENT_SSO_TOKEN_URI:
    IDENTITY_SERVICE_CONTENT_SSO_REDIRECT_URI:
    IDENTITY_SERVICE_RETRY_MAXATTEMPTS:
    IDENTITY_SERVICE_RETRY_DELAY:
```

### Additional java options
|  Variable   | Default |             Description                             |
|-------------|---------|-----------------------------------------------------|
| `JAVA_OPTS` |    None | can be used to pass additional JRE options          |

### Database configuration
| Variable                             | Default                                      | Description                          |
|--------------------------------------|----------------------------------------------|--------------------------------------|
| `ACTIVITI_DATASOURCE_URL`            | `jdbc:h2:mem:activiti;DB_CLOSE_DELAY=1000` | Database connection URL              |
| `ACTIVITI_DATASOURCE_DRIVER`   | `org.h2.Driver`                              | JDBC driver class name               |
| `ACTIVITI_DATASOURCE_USERNAME` | `alfresco`                                   | Database connection username         |
| `ACTIVITI_DATASOURCE_PASSWORD` | `alfresco`                                   | Database connection password         |
| `ACTIVITI_HIBERNATE_DIALECT`   | `org.hibernate.dialect.H2Dialect`           | Hibernate dialect for the database  |

### License configuration
| Variable                             | Default | Description                                      |
|--------------------------------------|---------|--------------------------------------------------|
| `ACTIVITI_LICENSE_MULTI_TENANT`      | `false` | Enable multi-tenant support in Activiti |

### Admin user configuration
| Variable                             | Default | Description                                      |
|--------------------------------------|---------|--------------------------------------------------|
| `ACTIVITI_ADMIN_EMAIL`               | `admin@app.activiti.com` | Email of the admin user for Activiti |
| `ACTIVITI_ADMIN_PASSWORD_HASH`       | `25a463679c56c474f20d8f592e899ef4cb3f79177c19e3782ed827b5c0135c466256f1e7b60e576e` | Password hash of the admin user for Activiti (admin)|

### Elasticsearch configuration
| Variable                             | Default | Description                                      |
|--------------------------------------|---------|--------------------------------------------------|
| `ACTIVITI_ES_SERVER_TYPE`            | `none`  | Type of Elasticsearch server to connect to |
| `ACTIVITI_ES_REST_CLIENT_ADDRESS`    | `localhost` | Address of the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_PORT`         | `9200`  | Port of the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_SCHEMA`         | `http`  | Schema of the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_AUTH_ENABLED` | `false` | Enable authentication for the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_USERNAME`   | `admin` | Username for the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_PASSWORD` | `esadmim` | Password for the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_KEYSTORE` | None | Keystore file for the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_KEYSTORE_TYPE` | `jks` | Type of the keystore for the Elasticsearch REST client |
| `ACTIVITI_ES_REST_CLIENT_KEYSTORE_PASSWORD` | None | Password for the keystore of the Elasticsearch REST client |

### CORS configuration
| Variable                             | Default | Description                                      |
|--------------------------------------|---------|--------------------------------------------------|
| `ACTIVITI_CORS_ENABLED`              | `true` | Enable CORS support |
| `ACTIVITI_CORS_ALLOWED_ORIGINS`      | None    | Comma-separated list of allowed origins for CORS requests |
| `ACTIVITI_CORS_ALLOWED_ORIGIN_PATTERNS` | `*` | Comma-separated list of allowed origin patterns for CORS requests |
| `ACTIVITI_CORS_ALLOWED_METHODS`      | `GET, POST, PUT, DELETE, OPTIONS` | Comma-separated list of allowed HTTP methods for CORS requests |
| `ACTIVITI_CORS_ALLOWED_HEADERS`      | `Authorization,Content-Type,Cache-Control,X-Requested-With,accept,Origin,Access-Control-Request-Method,Access-Control-Request-Headers,X-CSRF-Token` | Comma-separated list of allowed headers for CORS requests |

### CSRF configuration
| Variable                             | Default | Description                                      |
|--------------------------------------|---------|--------------------------------------------------|
| `ACTIVITI_CSRF_DISABLED`             | `false` | Disable CSRF protection |
| `ACTIVITI_REVIEW_WORKFLOWS_ENABLED` | None | Enable review workflows support |

### Identity service configuration
| Variable                             | Default | Description                                      |
|--------------------------------------|---------|--------------------------------------------------|
| `IDENTITY_SERVICE_ENABLED`           | `false` | Enable identity service integration |
| `IDENTITY_SERVICE_REALM`             | `alfresco` | Realm for the identity service |
| `IDENTITY_SERVICE_AUTH`              | `http://localhost:8180/auth` | Identity Service authentication server URL |
| `IDENTITY_SERVICE_RESOURCE`          | `alfresco` | Resource for the identity service |
| `IDENTITY_SERVICE_PRINCIPAL_ATTRIBUTE` | `email` | Principal attribute for user identification |
| `IDENTITY_CREDENTIALS_SECRET`        | None    | Secret for identity service credentials |
| `IDENTITY_SERVICE_USE_BROWSER_BASED_LOGOUT` | `false` | Use browser-based logout for identity service |
| `IDENTITY_SERVICE_CONTENT_SSO_ENABLED` | `false` | Enable SSO for content service |
| `IDENTITY_SERVICE_CONTENT_SSO_CLIENT_ID` | `alfresco` | Client ID for content SSO |
| `IDENTITY_SERVICE_CONTENT_SSO_CLIENT_SECRET` | None | Client secret for content SSO |
| `IDENTITY_SERVICE_CONTENT_SSO_REALM` | `alfresco` | Realm for content SSO |
| `IDENTITY_SERVICE_CONTENT_SSO_SCOPE` | `offline_access` | Scope for content SSO |
| `IDENTITY_SERVICE_CONTENT_SSO_AUTH_URI` | `${IDENTITY_SERVICE_AUTH}/realms/${IDENTITY_SERVICE_CONTENT_SSO_REALM}/protocol/openid-connect/auth` | Authentication URI for content SSO |
| `IDENTITY_SERVICE_CONTENT_SSO_TOKEN_URI` | `${IDENTITY_SERVICE_AUTH}/realms/${IDENTITY_SERVICE_CONTENT_SSO_REALM}/protocol/openid-connect/token` | Token URI for content SSO |
| `IDENTITY_SERVICE_CONTENT_SSO_REDIRECT_URI` | `http://localhost:8080/activiti-app/app/rest/integration/sso/confirm-auth-request` | Redirect URI after content SSO authentication |
| `IDENTITY_SERVICE_RETRY_MAXATTEMPTS` | `3` | Maximum number of retry attempts for identity service |
| `IDENTITY_SERVICE_RETRY_DELAY` | `1000` | Delay in milliseconds between retry attempts for identity service |

## Configuration file mounting

Instead of using environment variables, you can mount a complete configuration file with configmap or volume.:

```yaml
alfresco-activiti:
  image:
    repository: localhost/alfresco/alfresco-process-services
    tag: latest
  volumeMounts:
    - name: app-properties
      mountPath: /usr/local/tomcat/lib/activiti-app.properties
      subPath: activiti-app.properties
    - name: identity-properties
      mountPath: /usr/local/tomcat/lib/activiti-identity-service.properties
      subPath: activiti-identity.properties
  volumes:
    - name: app-properties
      configMap:
        name: aps-app-config
        items:
          - key: activiti-app.properties
            path: activiti-app.properties
    - name: identity-properties
      configMap:
        name: aps-app-identity-config
        items:
          - key: activiti-identity.properties
            path: activiti-identity.properties
```

When a properties file is mounted, environment variables are ignored and the mounted file is used as-is.
This is useful if you need to set properties which are not exposed as env vars.
