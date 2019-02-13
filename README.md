# Introduction

This docker image is more or less a clone of sonatype's [sonatype/nexus3](https://hub.docker.com/r/sonatype/nexus3/) image from the officiall docker hub repository.
It differs in:
- base image is alpine 3.8
- JVM is oracle [anapsix/alpine-java](https://hub.docker.com/r/anapsix/alpine-java/)
- [JVM is docker aware](https://efekahraman.github.io/2018/04/docker-awareness-in-java), -XX:+UseCGroupMemoryLimitForHeap, -XX:+UnlockExperimentalVMOptions
- set USER_UID + USER_GID for volume permissions

In this way the created image is very small compared to original. You can set USER_UID + USER_GID, which allows you to persist data in a host directoy without hadache.


# Run
```bash
    cd $HOME
    mkdir nexus-data

    docker run -d \
        -e USER_GID=$(id -g) \
        -e USER_UID=$(id -u) \
        -p 18081:8081 \
        -v $PWD/nexus-data:/nexus-data \
        --name nexus3 didlich/nexus3
```

# Build

```bash
docker build --rm=true --tag=didlich/nexus3 .
```

The following optional variables can be used when building the image:

- NEXUS_VERSION: Version of the Nexus Repository Manager
- NEXUS_DOWNLOAD_URL: Download URL for Nexus Repository, alternative to using
- NEXUS_VERSION to download from Sonatype
- NEXUS_DOWNLOAD_SHA256_HASH: Sha256 checksum for the downloaded Nexus Repository Manager archive. Required if *NEXUS_VERSION* or *NEXUS_DOWNLOAD_URL* is provided


# Test

```bash
curl -u admin:admin123 http://localhost:18081/service/metrics/ping
```


# Notes

- Default credentials are: admin / admin123
- It can take some time (2-3 minutes) for the service to launch in a new container. You can tail the log to determine once Nexus is ready:

```bash
docker logs -f nexus3
```

- Installation of Nexus is to /opt/sonatype/nexus.
- A persistent directory, /nexus-data, is used for configuration, logs, and storage. This directory needs to be writable by the Nexus process, which runs as USER_UID.
- There is an environment variable that is being used to pass JVM arguments to the startup script
    - INSTALL4J_ADD_VM_PARAMS, passed to the Install4J startup script. Defaults to
    - Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs.

This can be adjusted at runtime:

```bash
docker run -d \
    -p 8081:8081 \
    -e INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g -Djava.util.prefs.userRoot=/some-other-dir" \
    --name nexus didlich/nexus3
```

Of particular note, *-Djava.util.prefs.userRoot=/some-other-dir* can be set to a persistent path, which will maintain the installed Nexus Repository License if the container is restarted.

- Another environment variable can be used to control the Nexus Context Path
    - NEXUS_CONTEXT, defaults to /

This can be supplied at runtime:

```bash
docker run -d \
    -p 8081:8081 \
    -e NEXUS_CONTEXT=nexus \
    --name nexus didlich/nexus3
```

# Persistent Data

There are two general approaches to handling persistent storage requirements with Docker. See [Managing Data in Containers](https://docs.docker.com/engine/tutorials/dockervolumes/) for additional information.

1. Use a docker volume. Since docker volumes are persistent, a volume can be created specifically for this purpose. This is the recommended approach.

```bash
docker volume create --name nexus-data

docker run -d \
    -p 8081:8081 \
    -v nexus-data:/nexus-data \
    --name nexus  didlich/nexus3
```

2. Mount a host directory as the volume. For this it is required to set USER_GID and USER_UID.

```bash
docker run -d \
    -p 8081:8081 \
    -e USER_GID=$(id -g) \
    -e USER_UID=$(id -u) \
    -v /some/dir/nexus-data:/nexus-data \
    --name nexus didlich/nexus3
```