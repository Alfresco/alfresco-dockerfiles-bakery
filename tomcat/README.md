# Alfresco Base Tomcat image

## Description

This Dockerfile is used to build the base Tomcat image that every Alfresco Java web
application image is derived from. It ships Apache Tomcat (10.1 or 11.0,
depending on the ACS version being built) together with the Tomcat Native
library, and applies a set of hardening defaults to `conf/server.xml`.

## Building the image

You can build the image from the root of this git repository with the following
command:

```bash
docker buildx bake tomcat_base
```

## Running the image

### Tomcat configuration

The Tomcat settings that are most commonly tuned are exposed as environment
variables, all prefixed with `TOMCAT_`. Every variable has a default that
reproduces the behaviour of the image when the variable is left alone, so you
only need to set the ones you actually want to change:

```bash
docker run -e TOMCAT_HTTP_MAX_THREADS=400 -e TOMCAT_HTTP_MAX_POST_SIZE=104857600 \
  alfresco-content-repository:mytag
```

This relies on Tomcat's own [property replacement][systemprops] mechanism: the
image registers `org.apache.tomcat.util.digester.EnvironmentPropertySource` in
`conf/catalina.properties`, which makes Tomcat resolve the `${...}` placeholders
in `conf/server.xml` against the container's environment when it starts. The
values are therefore read at container startup, not at build time, and the same
variables work in every image built on top of this one.

[systemprops]: https://tomcat.apache.org/tomcat-10.1-doc/config/systemprops.html#Property_replacements

#### Server

See the [Server][server] documentation.

| Variable | Default | Description |
|---|---|---|
| `TOMCAT_SHUTDOWN_PORT` | `-1` | Port listening for the shutdown command. Disabled by default |
| `TOMCAT_VERSION_LOGGER_LOG_ARGS` | `false` | Log the JVM command line arguments at startup |
| `TOMCAT_VERSION_LOGGER_LOG_ENV` | `false` | Log the environment variables at startup |
| `TOMCAT_VERSION_LOGGER_LOG_PROPS` | `false` | Log the JVM system properties at startup |

[server]: https://tomcat.apache.org/tomcat-10.1-doc/config/server.html

#### HTTP connector

See the [HTTP connector][http] documentation.

| Variable | Default | Description |
|---|---|---|
| `TOMCAT_HTTP_PORT` | `8080` | TCP port the HTTP connector listens on |
| `TOMCAT_HTTP_CONNECTION_TIMEOUT` | `20000` | Milliseconds to wait for the request line after accepting a connection |
| `TOMCAT_HTTP_MAX_THREADS` | `200` | Maximum number of request processing threads |
| `TOMCAT_HTTP_MIN_SPARE_THREADS` | `10` | Number of threads kept running even when idle |
| `TOMCAT_HTTP_ACCEPT_COUNT` | `100` | Length of the OS accept queue used once all threads are busy |
| `TOMCAT_HTTP_MAX_CONNECTIONS` | `8192` | Maximum number of concurrent connections |
| `TOMCAT_HTTP_MAX_HTTP_HEADER_SIZE` | `8192` | Maximum size in bytes of the request and response headers |
| `TOMCAT_HTTP_MAX_POST_SIZE` | `2097152` | Maximum size in bytes of a form POST body. Raise it for large uploads |

`TOMCAT_HTTP_PORT` only changes the port Tomcat binds inside the container. The
image declares `EXPOSE 8080`, so if you move the connector you also need to
publish the new port yourself.

[http]: https://tomcat.apache.org/tomcat-10.1-doc/config/http.html

#### Web application deployment

See the [Host][host] documentation. Applications are baked into the derived
images, so automatic deployment is switched off by default.

| Variable | Default | Description |
|---|---|---|
| `TOMCAT_DEPLOY_XML` | `false` | Parse the `META-INF/context.xml` embedded in web applications |
| `TOMCAT_AUTO_DEPLOY` | `false` | Deploy new or updated applications while Tomcat is running |
| `TOMCAT_UNPACK_WARS` | `false` | Unpack WAR files before running them |

[host]: https://tomcat.apache.org/tomcat-10.1-doc/config/host.html

#### Reverse proxy handling

The image enables the [RemoteIpValve][valve] so that the client address, host,
port and protocol reported to the application reflect what the client sent to
the reverse proxy rather than the proxy's own connection.

| Variable | Default | Description |
|---|---|---|
| `TOMCAT_REMOTE_IP_HEADER` | `X-Forwarded-For` | Header carrying the originating client address |
| `TOMCAT_REMOTE_IP_PROTOCOL_HEADER` | `X-Forwarded-Proto` | Header carrying the protocol the client used |
| `TOMCAT_REMOTE_IP_PORT_HEADER` | `X-Forwarded-Port` | Header carrying the port the client connected to |
| `TOMCAT_REMOTE_IP_INTERNAL_PROXIES` | private and loopback ranges | Regular expression matching the proxies whose forwarded headers are trusted |
| `TOMCAT_REMOTE_IP_TRUSTED_PROXIES` | *(empty)* | Regular expression matching proxies that are trusted but should still appear in the proxies header |

The default `TOMCAT_REMOTE_IP_INTERNAL_PROXIES` is the regular expression Tomcat
itself ships, covering `10/8`, `172.16/12`, `192.168/16`, `169.254/16`,
`100.64/10`, `127/8`, `::1`, `fe80::/10` and `fc00::/7`. Set it to the address of
your ingress if you want to be stricter. Note that Tomcat 11 accepts CIDR
notation here but Tomcat 10 does not, so use a regular expression if you build
images for both.

Unlike the other variables, this one gets its default from an `ENV` in the
Dockerfile rather than from `server.xml`, because the regular expression contains
a closing brace. See the note at the end of this page.

[valve]: https://tomcat.apache.org/tomcat-10.1-doc/config/valve.html#Remote_IP_Valve

#### Error pages

See the [ErrorReportValve][errorvalve] documentation. Both are off by default so
that error pages do not leak information about the server or the application.

| Variable | Default | Description |
|---|---|---|
| `TOMCAT_ERROR_REPORT_SHOW_SERVER_INFO` | `false` | Include the Tomcat version in error pages |
| `TOMCAT_ERROR_REPORT_SHOW_REPORT` | `false` | Include the exception and stack trace in error pages |

[errorvalve]: https://tomcat.apache.org/tomcat-10.1-doc/config/valve.html#Error_Report_Valve

### Beyond these variables

Anything not covered above can still be configured:

- JVM options, including any Tomcat [system property][systemprops] that is not
  exposed here, go in `JAVA_OPTS` or `CATALINA_OPTS`, for example
  `-e CATALINA_OPTS="-Dorg.apache.catalina.STRICT_SERVLET_COMPLIANCE=true"`.
- Settings that live in `conf/catalina.properties`, such as the JAR scanning
  filters `tomcat.util.scan.StandardJarScanFilter.jarsToSkip` and `jarsToScan`,
  cannot be overridden with `-D`: Tomcat loads that file over the top of the
  system properties. Replace the file, or edit it in a derived image.
- For anything else, mount your own `conf/server.xml` over
  `/usr/local/tomcat/conf/server.xml`. Environment variable substitution stays
  available, so your file can use `${...}` placeholders too.

Two behaviours are worth knowing about when overriding these variables. Setting
one to an empty string is not the same as leaving it unset: the empty value is
substituted into `server.xml`, which for most attributes means "disabled". And a
value containing a closing brace cannot be used, because Tomcat ends the
placeholder at the first `}` it finds.
