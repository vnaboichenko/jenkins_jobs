#!/bin/bash
#set -ex
#set -o xtrace
#set -o errexit

# Generate plugin check/build script
cat <<END_SCRIPT > build.sh
#!/bin/bash
set -ex
find . -name '*.erb' -print0 | xargs -0 -P1 -L1 -I '%' erb -P -x -T '-' % | ruby -c
find . -name '*.pp' -print0 | xargs -0 -P1 -L1 puppet parser validate --verbose
find . -name '*.pp' -print0 | xargs -0 -r -P1 -L1 puppet-lint \\
          --with-context \\
          --with-filename \\
          --no-80chars-check \\
          --no-variable_scope-check \\
          --no-nested_classes_or_defines-check \\
          --no-autoloader_layout-check \\
          --no-class_inherits_from_params_class-check \\
          --no-documentation-check \\
          --no-arrow_alignment-check

fpb --check  ./
fpb --build  ./
END_SCRIPT

cat <<END_RPMCHECK > rpm-check.sh
#!/bin/bash

rs1='preinstall program: /bin/sh'
rs2='postinstall program: /bin/sh'
rs3='preuninstall program: /bin/sh'

pname=\$(grep '^name:' metadata.yaml)
pver=\$(grep '^version:' metadata.yaml)
cname=\$(echo "\${pname}"|cut -d ' ' -f 2)
cver=\$(echo "\${pver}"|cut -d ' ' -f 2|cut -d '.' -f 1,2)
msg=\$(rpm -qlp ./*.rpm |grep -v  /var/www/nailgun/plugins/"\${cname}-\${cver}")
if [ -z "\${msg}" ]; then
  echo "msg is clear"
fi
shs1=\$(rpm -qp --scripts ./*.rpm|grep 'preinstall program:')
shs2=\$(rpm -qp --scripts ./*.rpm|grep 'postinstall program:')
shs3=\$(rpm -qp --scripts ./*.rpm|grep 'preuninstall program:')
echo "\${shs1}"
echo "\${shs2}"
echo "\${shs3}"
if [[ -n \${shs1} && \${rs1} != \${shs1} ]]; then
  echo "Bad Preinstall Script"
  exit 1
fi
if [[ -n \${shs2} && \${rs2} != \${shs2} ]]; then
  echo "Bad Postinstall Script"
  exit 1
fi
if [[ -n \${shs3} && \${rs3} != \${shs3} ]]; then
  echo "Bad preuninstall Script"
  exit 1
fi
END_RPMCHECK

PLUGIN_DIR=${WORKSPACE}/pluginjobs_artifacts/${JOB_NAME}/${BUILD_ID}
if bash build.sh && bash rpm-check.sh; then
  [ -d "${PLUGIN_DIR}" ] && rm -rf "${PLUGIN_DIR}"
  mkdir -p "${PLUGIN_DIR}" && cp *.rpm "${PLUGIN_DIR}"
  [ -f *.txt ] && cp *.txt "${PLUGIN_DIR}"
  RPM_PATH="$(ls ${PLUGIN_DIR}/*.rpm)"
  if [[ -z "${RPM_PATH}" || $(echo "$RPM_PATH" | grep -c "\.rpm") -ne 1 ]]; then
    echo "ERROR: Cannot determine plugin's RPM path. Temporary directory ${PLUGIN_DIR} either does not contain any RPMs or has more than one RPM"
    exit 1
  fi
  RPM_NAME="${RPM_PATH##*/}"
  echo "BUILD_HOST=$(hostname -f)" > buildresult.params
  echo "PLUGIN_DIR=${PLUGIN_DIR}" >> buildresult.params
  RESULT=0
else
  RESULT=1
fi

echo "RESULT=${RESULT}" > setenvfile
[[ "${RPM_NAME}" == *".rpm" ]] && echo "RPM_NAME=${RPM_NAME}" >> setenvfile


if [[ $RPM_NAME =~ ^lbaas*  ]]; then
    echo 'CUSTOM_TEST_GROUP=deploy_neutron_lbaas_simple' >> setenvfile
  elif [[ $RPM_NAME =~ ^zabbix_monitoring*  ]]; then
    echo 'CUSTOM_TEST_GROUP=deploy_zabbix_ha' >> setenvfile
fi

cat setenvfile





exit 0
