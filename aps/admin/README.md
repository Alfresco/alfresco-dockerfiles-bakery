# Runtime variables

Sets of variables configurable with your docker image

## Alfresco Process Services Admin

```yaml
alfresco-activiti-admin:
  image:
    repository: localhost/alfresco/alfresco-process-services-admin
    tag: latest
  environment:
    JAVA_OPTS:
    ACTIVITI_ADMIN_DATASOURCE_URL:
    ACTIVITI_ADMIN_DATASOURCE_DRIVER:
    ACTIVITI_ADMIN_DATASOURCE_USERNAME:
    ACTIVITI_ADMIN_DATASOURCE_PASSWORD:
    ACTIVITI_ADMIN_HIBERNATE_DIALECT:
    ACTIVITI_ADMIN_REST_APP_HOST:
    ACTIVITI_ADMIN_REST_APP_PORT:
    ACTIVITI_ADMIN_REST_APP_USERNAME:
    ACTIVITI_ADMIN_REST_APP_PASSWORD:
    ACTIVITI_ADMIN_REST_APP_AUTHTYPE:
    ACTIVITI_ADMIN_REST_APP_SSO_ENABLED:
    ACTIVITI_ADMIN_REST_APP_SSO_AUTH_SERVER_URL:
    ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_ID:
    ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_SECRET:
    ACTIVITI_ADMIN_REST_APP_SSO_REALM:
    ACTIVITI_ADMIN_REST_APP_SSO_SCOPE:
    ACTIVITI_ADMIN_REST_APP_SSO_AUTH_URI:
    ACTIVITI_ADMIN_REST_APP_SSO_TOKEN_URI:
    ACTIVITI_ADMIN_REST_APP_SSO_REDIRECT_URI:
```

### Additional java options

|  Variable   | Default |             Description                             |
|-------------|---------|-----------------------------------------------------|
| `JAVA_OPTS` |    None | can be used to pass additional JRE options          |

### Database configuration

| Variable                             | Default                                      | Description                          |
|--------------------------------------|----------------------------------------------|--------------------------------------|
| `ACTIVITI_ADMIN_DATASOURCE_URL`      | `jdbc:h2:mem:activiti_admin;DB_CLOSE_DELAY=1000` | Database connection URL              |
| `ACTIVITI_ADMIN_DATASOURCE_DRIVER`   | `org.h2.Driver`                              | JDBC driver class name               |
| `ACTIVITI_ADMIN_DATASOURCE_USERNAME` | `alfresco`                                   | Database connection username         |
| `ACTIVITI_ADMIN_DATASOURCE_PASSWORD` | `alfresco`                                   | Database connection password         |
| `ACTIVITI_ADMIN_HIBERNATE_DIALECT`   | `org.hibernate.dialect.H2Dialect`           | Hibernate dialect for the database  |

### REST API configuration

| Variable                            | Default                        | Description                                      |
|-------------------------------------|--------------------------------|--------------------------------------------------|
| `ACTIVITI_ADMIN_REST_APP_HOST`      | `http://localhost`             | Host URL of the Process Services application    |
| `ACTIVITI_ADMIN_REST_APP_PORT`      | `8080`                         | Port of the Process Services application        |
| `ACTIVITI_ADMIN_REST_APP_USERNAME`  | `admin@app.activiti.com`       | Username to connect to Process Services REST API |
| `ACTIVITI_ADMIN_REST_APP_PASSWORD`  | `admin`                        | Password to connect to Process Services REST API |
| `ACTIVITI_ADMIN_REST_APP_AUTHTYPE`  | `basic`                        | Authentication type for REST API connection     |

### SSO configuration

| Variable                                      | Default| Description                                    |
|-----------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| `ACTIVITI_ADMIN_REST_APP_SSO_ENABLED`         | `true`| Enable/disable SSO authentication                  |
| `ACTIVITI_ADMIN_REST_APP_SSO_AUTH_SERVER_URL` | `https://acadev.envalfresco.com/auth` | SSO authentication server URL|
| `ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_ID`       | `alfresco`| SSO client ID                                  |
| `ACTIVITI_ADMIN_REST_APP_SSO_CLIENT_SECRET`   |  None | SSO client secret                                  |
| `ACTIVITI_ADMIN_REST_APP_SSO_REALM`           | `alfresco`| SSO realm name                                 |
| `ACTIVITI_ADMIN_REST_APP_SSO_SCOPE`           | `offline_access`| SSO scope                                |
| `ACTIVITI_ADMIN_REST_APP_SSO_AUTH_URI`        | `${rest.app.sso.auth-server-url}/realms/${rest.app.sso.realm}/protocol/openid-connect/auth`| SSO authorization endpointURL|
| `ACTIVITI_ADMIN_REST_APP_SSO_TOKEN_URI`       | `${rest.app.sso.auth-server-url}/realms/${rest.app.sso.realm}/protocol/openid-connect/token` | SSO token endpoint URL |
| `ACTIVITI_ADMIN_REST_APP_SSO_REDIRECT_URI`    | `http://localhost:8081/activiti-admin/app/rest/integration/sso/confirm-auth-request`| SSO redirect URI after authentication |

## Configuration file mounting

Instead of using environment variables, you can mount a complete configuration file with configmap or volume.:

```yaml
alfresco-activiti-admin:
  image:
    repository: localhost/alfresco/alfresco-process-services-admin
    tag: latest
  volumeMounts:
    - name: app-properties
      mountPath: /usr/local/tomcat/lib/activiti-admin.properties
      subPath: activiti-admin.properties
  volumes:
    - name: app-properties
      configMap:
        name: aps-admin-config
        items:
          - key: activiti-admin.properties
            path: activiti-admin.properties
```

When a properties file is mounted, the environment variable configuration is bypassed and the mounted file is
