#!/bin/bash

set -o xtrace
set -o errexit
set -o pipefail

START_TS=$(date +%s)

# Remove quotes, double and trailing slashes
REPO_URL=$(echo "${REPO_URL}" | sed 's|"||g; s|/\+|/|g; s|:|:/|g; s|/ | |g')
EXTRAREPO=$(echo "${EXTRAREPO}" | sed 's|"||g; s|/\+|/|g; s|:|:/|g; s|/ | |g')
EXTRAREPO="${EXTRAREPO}|http://mirror.fuel-infra.org/mos/ubuntu/ mos7.0 main restricted|http://mirror.fuel-infra.org/mos-repos/ubuntu/7.0/ mos7.0 main restricted"
PACKAGELIST=$(echo "${PACKAGELIST}" | sed 's|,| |g')
echo FAILED=false >> ci_status_params
RESULT=0


for script in version-test-deb vm-test repo-test-deb
do
    if [ -x "${WORKSPACE}/${script}" ]
    then
        if ! bash -x "${WORKSPACE}/${script}"
        then
            sed -i 's/FAILED=false/FAILED=true/' ci_status_params
            RESULT=1
        fi
    fi
done

TIME_ELAPSED=$(( $(date +%s) - ${START_TS} ))
echo "RESULT=${RESULT}" > setenvfile
echo "TIME_ELAPSED='$(date -u -d @${TIME_ELAPSED} +'%Hh %Mm %Ss' | sed 's|^00h ||; s|^00m ||')'" >> setenvfile

rm result.txt

