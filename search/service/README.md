# Alfresco Search Service image (Solr based)

## Description

This Docker file is used to build an Alfresco Serach Service image.

## Building the image

Make sure all required artifacts are present in the build context `search/service/`.
Use the script `./scripts/fetch-artifacts.sh` to download them from Alfresco's
Nexus.

Then, you can build the image from the root of this git repository with the
following command:

```bash
docker buildx bake repository
```

## Running the image

### Alfresco Search Service configuration

This image offers a set of environment variables one can use to change Search
service behaviour. The following table lists the available variables:

| Variable name | Description | Default value  |
|---------------|-------------|--------------- |
| ALFRESCO_HOST | hostname of the Alfresco content repository | `localhost` |
| ALFRESCO_PORT | port where the Alfresco content repository listens to connections | `8080`|
| ALFRESCO_PORT_SSL | port where the Alfresco content repository listens to secure connections (mtLS) | `8443` |
| ALFRESCO_BASEURL | The context where Alfresco content repository is serving requests | `/alfresco` |
| ALFRESCO_ENCRYPTION_SSL_KEYSTORE_TYPE | Type of keystore (used with ALFRESCO_SECURECOMMS=https) | `JCEKS` |
| ALFRESCO_ENCRYPTION_SSL_KEYSTORE_LOCATION | Location of the keystore file (used with `ALFRESCO_SECURECOMMS=https`) | `ssl.repo.client.keystore` |
| ALFRESCO_ENCRYPTION_SSL_KEYSTORE_PASSWORDFILELOCATION | Location of the file containing the keystore pass (used with `ALFRESCO_SECURECOMMS=https`) |  |
| ALFRESCO_ENCRYPTION_SSL_TRUSTSTORE_TYPE | Type of truststore | `JCEKS` |
| ALFRESCO_ENCRYPTION_SSL_TRUSTSTORE_LOCATION | Location of the trustore file (used with `ALFRESCO_SECURECOMMS=https`) | `ssl.repo.client.truststore` |
| ALFRESCO_ENCRYPTION_SSL_TRUSTSTORE_PASSWORDFILELOCATION | Location of the file containing the truststore password (used with `ALFRESCO_SECURECOMMS=https`) |  |
| ALFRESCO_SECURECOMMS | Type of authentication to use between Solr & Alfresco repository (`https` provides mTLS authentication while `secret` provides shared secret based auth. | `https` |
| ALFRESCO_SECURECOMMS_SECRET | Value of the shared secret to when `ALFRESCO_SECURECOMMS=secret`|  |
| ENABLE_REMOTE_JMX_OPTS | Enable plain, remote and unauthenticated access to JMX interface (debug only) | `false` |
| GC_LOG_OPTS | Java Garbage collector configuration options | |
| RMI_PORT | RMI port to use when JMX is enabled | `18983` |
| SOLR_DATA_DIR_ROOT | Location where actual index files are stored (should map to a volume) | `/opt/alfresco-search-services/data` |
| SOLR_DIRECTORY_FACTORY | Solr [Directory Factory](https://solr.apache.org/guide/6_6/datadir-and-directoryfactory-in-solrconfig.html#DataDirandDirectoryFactoryinSolrConfig-SpecifyingtheDirectoryFactoryForYourIndex) to use | `solr.StandardDirectoryFactory` |
| SOLR_HEAPSIZE | Amount of Heap memory Solr can use | `1g` |
| SOLR_HOME | Location of the Solr cores configuration & other configuration files (mount it as a volume to allow any type of custom configuration) | `/opt/alfresco-search-services/solrhome` |
| SOLR_HOST | Set to the externally reachable Solr hostname. Mostly usefullwith remote jmx acces with NAT | `localhost` |
| SOLR_LOCK_TYPE | Solr Type of [index locking](https://solr.apache.org/guide/8_1/indexconfig-in-solrconfig.html#index-locks) | `native` |
| SOLR_LOG_DIR | Location where should Solr log activity | `/opt/alfresco-search-services/logs` |
| SOLR_LOG_LEVEL | Minimum level of messages to be logged | `INFO` |
| SOLR_REPLICATION_MASTER | Is the Solr instance a master | `false` |
| SOLR_OPTS | Additional Solr options to pass to the JVM | |
| SOLR_REPLICATION_MASTER_URL | URL of the replication endpoint when behaving as a slave replica | Must be set if SOLR_REPLICATION_SLAVE is set to `true` |
| SOLR_REPLICATION_SLAVE | Is the Solr instance a slave replica | `false` |
| SOLR_SOLR_HOST | Set to the externally reachable Solr hostname. Only required when using Search service JDBC endpoint | |

## Solr configuration

Use the environment variables above if you need to change the default Solr
configuration. There are more options available to configure Solr, but they are
not exposed as environment variables. If you need to change them, you can mount
a volume with your custom configuration files. The volume should be mounted at
`/opt/alfresco-search-services/solrhome`.

```bash
docker run -d \
  -p 8983:8983 \
  -v <NAMED_VOLUME>:/opt/alfresco-search-services/solrhome \
  localhost/alfresco/alfresco-search-service:latest
``` 

This volume needs to be initialiazed with some default configuration files.
You can either download the Alfresco Search Service archive and extract the
`solrhome` directory from it, or you copy the `solrhome` directory from the
image to your host. The latter guarantees that you have the same version of the
configuration files as the inital image.
To do this, you can run the following command:

```bash
mkdir -p solrhome
docker volume create \
  --driver local \
  -o o=bind -o type=none \
  -o device="$PWD/solrhome" solrhome
docker run --rm \
  -v solrHome:/opt/alfresco-search-services/solrhome \
  localhost/alfresco/alfresco-search-service:latest
```

This will dump the original content of the image ina a local `solrhome`
directory, including:

 * `rerank` & `noRerank` template core configurations.
 * the `conf/shared.properties` file.

You can proceed to the configuration changes you need, then copy the edited
files to the final destination volume.

### Cross locale search

Cross locale search
[configuration](https://docs.alfresco.com/insight-engine/latest/config/indexing/#cross-locale)
should be done in the `$SOLR_HOME/shared.properties` file.

### Fingerprint configuration

Toggling also requires using a volume for the `solrhome` directory. For
furthter information, please refer to the
[official
documentation](https://docs.alfresco.com/insight-engine/latest/config/performance/#disable-document-fingerprint)

### Solr Caches configuration

The Solr caches configuration can be done in the `solrcore.properties` file
and so requires a volume for the `solrhome` directory. For further information,
please refer to the [cache configuration
documentation](https://docs.alfresco.com/insight-engine/latest/config/performance/#disable-solr-document-cache)

### Merging configuration

Index merging is a command and often sensitive operation. You may want to
configure it to your needs. Solr again, do not expose environment variables for
this, so you need to use a volume for the `solrhome` directory. For further
information, please refer to the [Merging Parameters
documentation](https://docs.alfresco.com/insight-engine/latest/config/performance/#merging-parameters)

## Solr replication

Solr can be setup in a Master/Slave architecture. This image offers a set of
environment variables to configure the replication.

### Running a container as a master

To run a container as a Master, you need to set the following environment:

```bash
docker run -d \
  -e SOLR_REPLICATION_MASTER=true \
  -p 8983:8983 \
  localhost/alfresco/alfresco-search-service:latest
```

You can further tweak the replication configuration by setting some solr
properties directly using `SOLR_OPTS` environment variable. For example, to
change the replication triggers, you can run the following command:

```bash
docker run -d \
  -e SOLR_REPLICATION_MASTER=true \
  -e SOLR_OPTS="-Dsolr.replication.replicate.after=optimize" \
  -p 8983:8983 \
  localhost/alfresco/alfresco-search-service:latest
```

available properties are:

 * `solr.replication.replicate.after` - default is `commit`
 * `solr.replication.conf.files` - default is `schema.xml,stopwords.txt`

### Running a container as a slave

To run a container as a slave, you need to set the following environment:

```bash
docker run -d \
  -e SOLR_REPLICATION_SLAVE=true \
  -p 8983:8983 \
  localhost/alfresco/alfresco-search-service:latest
```

You can further tweak the replication configuration by setting some solr
properties directly using `SOLR_OPTS` environment variable. For example, to
change the replication triggers, you can run the following command:

```bash
docker run -d \
  -e SOLR_REPLICATION_SLAVE=true \
  -e SOLR_REPLICATION_MASTER_URL=https://primary.domain.tld/solr/corename/replication \
  -e SOLR_OPTS="-Dsolr.replication.poll.interval=00:01:00" \
  -p 8983:8983 \
  localhost/alfresco/alfresco-search-service:latest
```

available properties are:

 * `solr.replication.poll.interval` - default is `00:00:30`
