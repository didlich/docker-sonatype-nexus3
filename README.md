# Build
docker build -t alpine-nexus3 --rm=true .

The following optional variables can be used when building the image:

    NEXUS_VERSION: Version of the Nexus Repository Manager
    NEXUS_DOWNLOAD_URL: Download URL for Nexus Repository, alternative to using NEXUS_VERSION to download from Sonatype
    NEXUS_DOWNLOAD_SHA256_HASH: Sha256 checksum for the downloaded Nexus Repository Manager archive. Required if NEXUS_VERSION or NEXUS_DOWNLOAD_URL is provided


# Run
    cd $HOME
    mkdir nexus-data

    docker run -d \
        -e USER_GID=$(id -g) \
        -e USER_UID=$(id -u) \
        -p 18081:8081 \
        -v $PWD/nexus-data:/nexus-data \
        --name nexus3 alpine-nexus3

# Test

curl -u admin:admin123 http://localhost:8081/service/metrics/ping

# Notes

Default credentials are: admin / admin123



    It can take some time (2-3 minutes) for the service to launch in a new container. You can tail the log to determine once Nexus is ready:

    docker logs -f nexus



Installation of Nexus is to /opt/sonatype/nexus.

A persistent directory, /nexus-data, is used for configuration, logs, and storage. This directory needs to be writable by the Nexus process, which runs as UID 200.

There is an environment variable that is being used to pass JVM arguments to the startup script

    INSTALL4J_ADD_VM_PARAMS, passed to the Install4J startup script. Defaults to -Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs.

This can be adjusted at runtime:

    docker run -d -p 8081:8081 --name nexus -e INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g  -Djava.util.prefs.userRoot=/some-other-dir" sonatype/nexus3

Of particular note, -Djava.util.prefs.userRoot=/some-other-dir can be set to a persistent path, which will maintain the installed Nexus Repository License if the container is restarted.



Another environment variable can be used to control the Nexus Context Path

    NEXUS_CONTEXT, defaults to /

This can be supplied at runtime:

    docker run -d -p 8081:8081 --name nexus -e NEXUS_CONTEXT=nexus sonatype/nexus3


#Persistent Data

There are two general approaches to handling persistent storage requirements with Docker. See [Managing Data in Containers](https://docs.docker.com/engine/tutorials/dockervolumes/) for additional information.

    Use a docker volume. Since docker volumes are persistent, a volume can be created specifically for this purpose. This is the recommended approach.

    docker volume create --name nexus-data
    docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3

    Mount a host directory as the volume. For this it is required to set USER_GID and USER_UID.

    docker run -d -p 8081:8081 -e USER_GID=$(id -g) -e USER_UID=$(id -u) --name nexus -v /some/dir/nexus-data:/nexus-data sonatype/nexus3
