#!/usr/bin/env bash
set -e

echo "USER_GID: "$USER_GID
echo "USER_UID: "$USER_UID

## Change GID for USER?
if [ -n "${USER_GID}" ] && [ "${USER_GID}" != "`id -g ${NEXUS_USER}`" ]; then
    sed -i -e "s/^${NEXUS_USER}:\([^:]*\):[0-9]*/${NEXUS_USER}:\1:${USER_GID}/" /etc/group
    sed -i -e "s/^${NEXUS_USER}:\([^:]*\):\([0-9]*\):[0-9]*/${NEXUS_USER}:\1:\2:${USER_GID}/" /etc/passwd
    chown -R --dereference -L ${NEXUS_USER}:${NEXUS_GROUP} ${NEXUS_HOME}
fi

## Change UID for USER?
if [ -n "${USER_UID}" ] && [ "${USER_UID}" != "`id -u ${NEXUS_USER}`" ]; then
    sed -i -e "s/^${NEXUS_USER}:\([^:]*\):[0-9]*:\([0-9]*\)/${NEXUS_USER}:\1:${USER_UID}:\2/" /etc/passwd
    chown -R --dereference -L ${NEXUS_USER}:${NEXUS_GROUP} ${NEXUS_HOME}
fi

[ -d "${NEXUS_DATA}" ] || mkdir -p "${NEXUS_DATA}"
[ $(stat -c '%U' "${NEXUS_DATA}") != 'neuxs' ] && chown -R nexus "${NEXUS_DATA}"

# clear tmp and cache for upgrade
rm -fr "${NEXUS_DATA}"/tmp/ "${NEXUS_DATA}"/cache/

[ $# -eq 0 ] && \
    su-exec ${NEXUS_USER} /opt/sonatype/nexus/bin/nexus run
