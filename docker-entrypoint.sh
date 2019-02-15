#!/usr/bin/env bash
set -e

echo "USER_GID: "$USER_GID
echo "USER_UID: "$USER_UID

PREV_NEXUS_UID=$(id -u ${NEXUS_USER})
PREV_NEXUS_GID=$(id -g ${NEXUS_USER})

## change GID for USER?
if [ -n "${USER_GID}" ] && [ "${USER_GID}" != "`id -g ${NEXUS_USER}`" ]; then
    echo "changing GID from '${PREV_NEXUS_GID}' to '${USER_GID}' ..."
    sed -i -e "s/^${NEXUS_USER}:\([^:]*\):[0-9]*/${NEXUS_USER}:\1:${USER_GID}/" /etc/group
    sed -i -e "s/^${NEXUS_USER}:\([^:]*\):\([0-9]*\):[0-9]*/${NEXUS_USER}:\1:\2:${USER_GID}/" /etc/passwd
    NEED_CHANGE_GID=1
fi

## change UID for USER?
if [ -n "${USER_UID}" ] && [ "${USER_UID}" != "`id -u ${NEXUS_USER}`" ]; then
    echo "changing UID from '${PREV_NEXUS_UID}' to '${USER_UID}' ..."
    sed -i -e "s/^${NEXUS_USER}:\([^:]*\):[0-9]*:\([0-9]*\)/${NEXUS_USER}:\1:${USER_UID}:\2/" /etc/passwd
    NEED_CHANGE_UID=1
fi

## change NEXUS_HOME permission
if [ -n "${NEED_CHANGE_GID}" ] || [ -n "${NEED_CHANGE_UID}" ]; then
    echo "start changing permission of HOME '${NEXUS_HOME}' ..."
    chown -R --dereference -L ${NEXUS_USER}:${NEXUS_GROUP} ${NEXUS_HOME}
    echo "finished changing HOME permission"
fi

[ -d "${NEXUS_DATA}" ] || echo "creating data directory '${NEXUS_DATA}' ..." && mkdir -p "${NEXUS_DATA}"

if [ $(stat -c '%U' "${NEXUS_DATA}") != "${NEXUS_USER}" ]; then
    echo "'${NEXUS_DATA}' expect owner '$NEXUS_USER', but is $(stat -c '%U' "${NEXUS_DATA}")"
    echo "start changing owner ..."
    chown -R $NEXUS_USER "${NEXUS_DATA}"
    echo "finished changing"
fi


# clear tmp and cache for upgrade
echo "start clearing '${NEXUS_DATA}/tmp/' and '${NEXUS_DATA}/cache/' ..."
rm -fr "${NEXUS_DATA}"/tmp/ "${NEXUS_DATA}"/cache/
echo "finished clearing"

[ $# -eq 0 ] && \
    su-exec ${NEXUS_USER} /opt/sonatype/nexus/bin/nexus run
