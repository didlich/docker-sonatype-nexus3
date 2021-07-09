FROM anapsix/alpine-java:8_server-jre

LABEL maintainer="didlich.apps@gmail.com"

ARG NEXUS_VERSION=3.29.0-02
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz
ARG NEXUS_DOWNLOAD_SHA256_HASH=1fe59c73016f211e7a26e23df404cf34a10121d26ed84676629dd29dbc1fb37b

ENV NEXUS_USER nexus
ENV NEXUS_GROUP nexus

# configure nexus runtime
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
    NEXUS_DATA=/nexus-data \
    NEXUS_CONTEXT='' \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work \
    DOCKER_TYPE='docker'

# install nexus
RUN apk update && apk add openssl su-exec && rm -fr /var/cache/apk/*
RUN mkdir -p ${SONATYPE_DIR} \
  && wget https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz -O - \
  | tar zx -C "${SONATYPE_DIR}" && rm -fr ${SONATYPE_WORK} \
  && mv "${SONATYPE_DIR}/nexus-${NEXUS_VERSION}" "${NEXUS_HOME}"

# configure nexus
RUN sed \
    -e '/^nexus-context/ s:$:${NEXUS_CONTEXT}:' \
    -i ${NEXUS_HOME}/etc/nexus-default.properties

## create nexus user
RUN addgroup -S "${NEXUS_GROUP}" \
    && adduser -D -H -h "${NEXUS_DATA}" -s /bin/false -S -G "${NEXUS_USER}" "${NEXUS_GROUP}"

RUN mkdir -p "${NEXUS_DATA}/etc" "${NEXUS_DATA}/log" "${NEXUS_DATA}/tmp" "${SONATYPE_WORK}"
RUN ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3

## prevent warning: /opt/sonatype/nexus/etc/org.apache.karaf.command.acl.config.cfg (Permission denied) 
RUN chown -R "${NEXUS_USER}":"${NEXUS_GROUP}" "${NEXUS_HOME}/etc/"

COPY docker-entrypoint.sh /

VOLUME ${NEXUS_DATA}

EXPOSE 8081
WORKDIR ${NEXUS_HOME}

ENV INSTALL4J_ADD_VM_PARAMS="-Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"


ENTRYPOINT ["/docker-entrypoint.sh"]
