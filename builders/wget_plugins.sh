#!/bin/bash


find ${PLUGINS_DIR} -name *.rpm | xargs rm  2>>/dev/null || true

#stable_plugins_url='http://mirror.ci-cd-aut.local/plugins/repository/'
#stable_plugins_dir="${PLUGINS_DIR}/stable"


temporary_plugins_url=${PLUGINS}
temporary_plugins_dir="${PLUGINS_DIR}/temporary"

#wget --directory-prefix=${stable_plugins_dir} -r -nH --cut-dirs=2 --no-parent --reject="index.html*" ${stable_plugins_url}

if [ ! -z "$temporary_plugins_url" ]
then
    wget --directory-prefix=${temporary_plugins_dir}  ${temporary_plugins_url}
fi
