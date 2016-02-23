#!/bin/bash

set -x

TEST_ISO_JOB_URL="https://product-ci.infra.mirantis.net/job/7.0.test_all/"

###################### Get MIRROR HOST ###############

#LOCATION_FACT=$(facter --external-dir /etc/facter/facts.d/ location)
LOCATION=${LOCATION_FACT:-bud}

case "${LOCATION}" in
    srt)
        MIRROR_HOST="http://osci-mirror-srt.srt.mirantis.net/pkgs/"
        ;;
    msk)
        MIRROR_HOST="http://osci-mirror-msk.msk.mirantis.net/pkgs/"
        ;;
    kha)
        MIRROR_HOST="http://osci-mirror-kha.kha.mirantis.net/pkgs/"
        ;;
    poz)
        MIRROR_HOST="http://osci-mirror-poz.poz.mirantis.net/pkgs/"
        ;;
    bud)
        MIRROR_HOST="http://mirror.seed-cz1.fuel-infra.org/pkgs/"
        ;;
    bud-ext)
        MIRROR_HOST="http://mirror.seed-cz1.fuel-infra.org/pkgs/"
        ;;
    mnv|scc)
        MIRROR_HOST="http://mirror.seed-us1.fuel-infra.org/pkgs/"
        ;;
    *)
        MIRROR_HOST="http://mirror.fuel-infra.org/pkgs/"
esac

###################### Get MIRROR_UBUNTU ###############

if [[ ! "${MIRROR_UBUNTU}" ]]; then

    case "${UBUNTU_MIRROR_ID}" in
        latest-stable)
            UBUNTU_MIRROR_ID="$(curl -fsS "${TEST_ISO_JOB_URL}lastSuccessfulBuild/artifact/ubuntu_mirror_id.txt" | awk -F '[ =]' '{print $NF}')"
            UBUNTU_MIRROR_URL="${MIRROR_HOST}${UBUNTU_MIRROR_ID}/"
            ;;
        latest)
            UBUNTU_MIRROR_URL="$(curl ${MIRROR_HOST}ubuntu-latest.htm)"
            ;;
        *)
            UBUNTU_MIRROR_URL="${MIRROR_HOST}${UBUNTU_MIRROR_ID}/"
    esac

    export MIRROR_UBUNTU="deb ${UBUNTU_MIRROR_URL} trusty main universe multiverse|deb ${UBUNTU_MIRROR_URL} trusty-updates main universe multiverse|deb ${UBUNTU_MIRROR_URL} trusty-security main universe multiverse|deb ${UBUNTU_MIRROR_URL} trusty-proposed main universe multiverse"
fi

if [[ "${NETWORK_MODE}" == "Neutron/VLAN" ]]; then
  export NEUTRON_ENABLE="true"
  export NEUTRON_SEGMENT_TYPE="vlan"
fi

if [[ "${NETWORK_MODE}" == "Neutron/GRE" ]]; then
  export NEUTRON_ENABLE="true"
  export NEUTRON_SEGMENT_TYPE="gre"
fi

if [[ "${NETWORK_MODE}" == "Neutron/VXLAN" ]]; then
  export NEUTRON_ENABLE="true"
  export NEUTRON_SEGMENT_TYPE="tun"
fi

# Checking gerrit commits for fuel-qa
if [[ "${fuel_qa_gerrit_commit}" != "none" ]] ; then
  for commit in ${fuel_qa_gerrit_commit} ; do
    git fetch https://review.openstack.org/openstack/fuel-qa "${commit}" && git cherry-pick FETCH_HEAD
  done
fi

# Check if custom test group is specified
if [[ ! -z "${CUSTOM_TEST_GROUP}" ]]; then
  export TEST_GROUP="${CUSTOM_TEST_GROUP}"
fi

export VENV_PATH="/home/jenkins/venv-nailgun-tests-2.9"
rm -rf logs/*

export MAKE_SNAPSHOT=${MAKE_SNAPSHOT}
ISO_PATH=$(seedclient-wrapper -d -m "${MAGNET_LINK}" -v --force-set-symlink -o "${WORKSPACE}")
echo "${ISO_PATH}"

# Fix parameters for ha_neutron_destructive test
if [[ "${TEST_GROUP}" == "ha_neutron_destructive" ]]; then
  export NEUTRON_ENABLE="true"
fi

#ENV_NAME=${ENV_PREFIX}.${BUILD_NUMBER}.${BUILD_ID}
#export ENV_NAME=${ENV_NAME:0:68}
export ENV_NAME=$ENV_PREFIX

export PATH_TO_CERT=${WORKSPACE}"/"${ENV_NAME}".crt"
export PATH_TO_PEM=${WORKSPACE}"/"${ENV_NAME}".pem"

export OPENSTACK_RELEASE="${OPENSTACK_RELEASE}"

echo "Description string: ${TEST_GROUP} on ${NODE_NAME}: ${ENV_NAME}"

if sh -x "utils/jenkins/system_tests.sh" -k -t test -w "${WORKSPACE}" -e $ENV_NAME -V "${VENV_PATH}" -j "${JOB_NAME}" -o --group="${TEST_GROUP}" -i ${ISO_PATH}
then 
  RESULT=0
else 
  RESULT=1
fi

echo "RESULT=${RESULT}" > setenvfile

