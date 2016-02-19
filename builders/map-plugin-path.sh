#!/bin/bash

set -ex

# Check if custom test group is specified
if [[ ! -z "${CUSTOM_TEST_GROUP}" ]]; then
  export TEST_GROUP="${CUSTOM_TEST_GROUP}"
fi

get_plugin_path()
{
    if [[ -z "$1" ]]; then
       echo "Parameter required. Specify plugin name pattern for search" >&2
       exit 1
    fi
      cd $PLUGINS_DIR
      if find -name ${1}*.rpm | grep -q temporary ;
         then
             plugin=`find -name ${1}*.rpm | grep temporary`
             echo "${plugin}"; return;
         else
             plugin=`find -name ${1}*.rpm`;
             echo $plugin;  return;
       fi
    cd -
    echo "ERROR: Path to plugin with pattern $1 cannot be determined. Check 'PLUGINS job parameter" >&2
    #exit 1
}



case "${TEST_GROUP}" in
        "deploy_zabbix_ha"|"deploy_zabbix")
                echo "ZABBIX_PLUGIN_PATH=$PLUGINS_DIR/$(get_plugin_path zabbix_monitoring)" > plugins.parameters
                ;;
        "deploy_neutron_lbaas_simple")
                echo "LBAAS_PLUGIN_PATH=$PLUGINS_DIR/$(get_plugin_path lbaas)" >> plugins.parameters
                ;;
        *)
                echo "WARNING: Cannot automatically determine *_PLUGIN_PATH variables for ${TEST_GROUP}. Required plugins may not be found." >&2
                ;;
esac
