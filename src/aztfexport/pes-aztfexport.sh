#!/usr/bin/env bash
# WARN: !! aztfexport ask's and then deletes directory where you run it.
set -eu
version="1.5-20250712"
# 2025-07-12 v1.5 Add option to set provider from azurerm to azapi. export AZTFEXPORT_PROVIDER="azapi"
# 2025-04-24 v1.4 Use rust_aztfexport_rename replacing pes_search_and_replace.py
# 2025-04-16 v1.3 Update version tf 1.11.0  and  aztfexport 0.17.1
# 2024-08-21 v1.2 Add pes_search_and_replace.py to rename aztfexportResourceMapping.json
# 2024-08-21 v1.1 Add env vars for subscription and resource-group.
# 2024-05-01 v1.0 Shell scripts to run aztfexport and create terraform templates.
#
AZTFEXPORT_SUBSCRIPTION_ID="${AZTFEXPORT_SUBSCRIPTION_ID}"
AZTFEXPORT_RG="${AZTFEXPORT_RG}"
AZURERM="4.26.0"
PROVIDER="${AZTFEXPORT_PROVIDER:-'azurerm' --provider-version='$AZURERM'}"
#
echo " Logged in with:  az login --use-device-code"
az account set --subscription "$AZTFEXPORT_SUBSCRIPTION_ID"
if [[ -z "${1+NoValue}" ]]; then
    echo " Needs parameter ?  'query' 'map'  or 'rg'"
    exit 1
fi
#
tf_version="1.11.0"
echo "# switch to terraform version: $tf_version"
tfswitch $tf_version
echo; sleep 2;
#
out_dir="aztf_out"
echo "# delete all content of $out_dir/"
set -x
rm -rf $out_dir/* 
rm -rf $out_dir/.terraf*
#
if [[ "$1" == "rg" ]]; then
    echo "#1 aztfexport resource-group ... '$AZTFEXPORT_RG" ; sleep 2;
    aztfexport resource-group \
        --output-dir="$out_dir" \
        --subscription-id="$AZTFEXPORT_SUBSCRIPTION_ID" \
        --provider-name="$PROVIDER" \
        --non-interactive="true" \
        --generate-mapping-file="false" \
        --generate-import-block="false" \
        "$AZTFEXPORT_RG"
    rc=$?
    set +x
    if [[ $rc -ne 0 ]]; then
        echo; echo "# ERROR: aztfexport rg failed. AZTFEXPORT_RG=\"$AZTFEXPORT_RG\""
        exit 1
    fi
elif [[ "$1" == "query" ]]; then
    echo "#2 aztfexport query ... with filter ..." ; sleep 2;
    aztfexport query \
        --output-dir="$out_dir" \
        --subscription-id="$AZTFEXPORT_SUBSCRIPTION_ID" \
        --provider-name="$PROVIDER" \
        --generate-mapping-file="false" \
        --generate-import-block="false" \
        --non-interactive="true" \
        "resourceGroup =~ '$AZTFEXPORT_RG' and ( type contains 'Microsoft.Network' or type contains 'Microsoft.Compute/virtualMachines' or type contains 'azurerm_resource_group' or type contains 'azurerm_arc_machine')"
    # Notes: Just 'Microsoft.Compute' includes snapshots
    rc=$?
    set +x
    if [[ $rc -ne 0 ]]; then
        echo; echo "# ERROR: aztfexport query failed. Check the query filter."
        exit 1
    fi
elif [[ "$1" == "map" ]]; then
    map_file="../azTfExpResMapIn.json"
    echo "#3 aztfexport mapping-file read ... '$map_file' " ; sleep 2;
    aztfexport mapping-file \
        --output-dir="$out_dir" \
        --subscription-id="$AZTFEXPORT_SUBSCRIPTION_ID" \
        --provider-name="$PROVIDER" \
        --generate-import-block="true" \
        --non-interactive="true" \
        $map_file
else
    echo "# need a selection ? 'query', 'rg' or 'map'"
fi

## If query or rg, rename and copy file to ../azTfExpResMapIn.json
if [[ "$1" == "rg" ]] || [[ "$1" == "query" ]]; then 
    echo; echo "# aztfexport $1 done."
    sleep 2;
    echo "# rename file in ./aztf_out/aztfexportResourceMapping.json to ./aztf_out/aztfexportResourceMapping.json.out"
    echo ; sleep 2;
    # rename file in ./aztf_out/aztfexportResourceMapping.json to ./aztf_out/aztfexportResourceMapping.json.out
    /usr/local/bin/rust_aztfexport_rename --src "./aztf_out/aztfexportResourceMapping.json" --dst "./aztf_out/aztfexportResourceMapping.json.out"
    echo
    echo "# cp renamed ./aztf_out/aztfexportResourceMapping.json.out to ../azTfExpResMapIn.json"
    sleep 2;
    cp ./aztf_out/aztfexportResourceMapping.json.out ../azTfExpResMapIn.json
    cp ./aztf_out/aztfexportResourceMapping.json ../azTfExpResMapOriginal.json
    echo "# done. run 'pes-aztfexport.sh map' to create terraform templates next."
    sleep 2;
fi

echo; echo "# aztfexport done."
