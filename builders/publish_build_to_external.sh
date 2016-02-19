#!/bin/bash

set -ex

LOGS="${WORKSPACE}/logs/"

rm -rf "${LOGS}"

mkdir -p "${LOGS}"

if [[ ! -z "${BUILD_HOST}" && ! -z "${PLUGIN_DIR}" ]]; then
  rsync -avPzt \
      -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${SSH_OPTS}" \
      ${SSH_USER}${BUILD_HOST}:${PLUGIN_DIR}/ ${LOGS}/ || error "Can't download packages"
fi

if [[ "${STORE_LOGS}" == "true" || "${STORE_LOGS}" == "True" ]]; then  wget --no-check-certificate "${REPORTED_JOB_URL}/${REPORTED_BUILD_ID}/consoleText" -O "${LOGS}/consoleText.txt"; fi

echo ${PUBLISH_PATH}


