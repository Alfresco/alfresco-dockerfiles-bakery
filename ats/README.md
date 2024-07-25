# Runtime variables

Sets of variables configurable with your docker image

## trouter

```yaml

transform-router:
    image: alfresco-transform-router:YOUR-TAG
    environment:
      JAVA_OPTS: 
      ACTIVEMQ_URL: nio://activemq:61616
      ACTIVEMQ_USER: "admin"
      ACTIVEMQ_PASSWORD: "admin"

      CORE_AIO_URL: http://transform-core-aio:8090
      FILE_STORE_URL: http://shared-file-store:8099/alfresco/api/-default-/private/sfs/versions/1/file

      TRANSFORMER_ENGINE_PROTOCOL: jms

      IMAGEMAGICK_URL: "http://imagemagick:8090"
      PDF_RENDERER_URL: "http://alfresco-pdf-renderer:8090"
      LIBREOFFICE_URL: "http://libreoffice:8090"
      TIKA_URL: "http://tika:8090"
      MISC_URL: "http://misc:8090"

```

- `JAVA_OPTS` - Additional java options
- `ACTIVEMQ_URL` - The URL for Alfresco ActiveMQ.
- `ACTIVEMQ_USER` - The username for ActiveMQ.
- `ACTIVEMQ_PASSWORD` - The password for ActiveMQ.
- `CORE_AIO_URL` - Transform Core AIO server
- `FILE_STORE_URL` - The URL for the Alfresco Shared FileStore endpoint.
- `TRANSFORMER_ENGINE_PROTOCOL` - Specifies the protocol used by the transform engine. For example, `jms`.
- `IMAGEMAGICK_URL` - The URL for the ImageMagick service
- `PDF_RENDERER_URL` - The URL for the PDF Renderer service
- `LIBREOFFICE_URL` - The URL for the LibreOffice service
- `TIKA_URL` - The URL for the Tika service
- `MISC_URL` - The URL for Mics service
