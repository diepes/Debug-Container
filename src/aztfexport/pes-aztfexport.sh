#!/usr/bin/env bash
# WARN: !! aztfexport ask's and then deletes directory where you run it.
set -eu
version="1.0-20240501"
# 2024-05-01 v1.0 Shell scripts to run aztfexport and create terraform templates.
#
AZTFEXPORT_SUBSCRIPTION_ID="<..>"
AZTFEXPORT_RG="dev-rg"
#

echo " Logged in with:  az login --use-device-code"
az account set --subscription "$AZTFEXPORT_SUBSCRIPTION_ID"
if [[ -z "${1+NoValue}" ]]; then
    echo " Needs parameter ?  'query' 'map'  or 'rg'"
    exit 1
fi


set -x
out_dir="aztf_out"
echo "# delete all content of $out_dir/"
rm -rf $out_dir/* 
rm -rf $out_dir/.terraf*

if [[ "$1" == "rg" ]]; then
echo "#1 aztfexport resource-group ..." ; sleep 2;
aztfexport resource-group \
    --output-dir="$out_dir" \
    --subscription-id="$AZTFEXPORT_SUBSCRIPTION_ID" \
    --provider-name="azurerm" \
    --provider-version="3.99.0" \
    --non-interactive="false" \
    --generate-mapping-file="false" \
    --generate-import-block="true" \
    --hcl-only="true" \
    "$AZTFEXPORT_RG"

elif [[ "$1" == "query" ]]; then
echo "#2 aztfexport query ..." ; sleep 2;
aztfexport query \
    --output-dir="$out_dir" \
    --subscription-id="$AZTFEXPORT_SUBSCRIPTION_ID" \
    --provider-name="azurerm" \
    --provider-version="3.99.0" \
    -n "resourceGroup =~ '$AZTFEXPORT_RG' and ( type contains 'Microsoft.Network' or type contains 'Microsoft.Compute/virtualMachines' or type contains 'azurerm_resource_group' )"
# Notes: Just 'Microsoft.Compute' includes snapshots
set +x
echo; echo "# next './pes-search_and_replace.py' then 'mv to parent folder. then './pes-aztfexport.sh map' next ..."

elif [[ "$1" == "map" ]]; then
map_file="./aztfexportResourceMapping.json.out"
echo "#3 aztfexport mapping-file read ... '$map_file' " ; sleep 2;

aztfexport mapping-file \
    --output-dir="$out_dir" \
    --subscription-id="$AZTFEXPORT_SUBSCRIPTION_ID" \
    --provider-name="azurerm" \
    --provider-version="3.99.0" \
    --generate-import-block="true" \
    --non-interactive="true" \
    $map_file

else
    echo "# need a selection ?"
fi
echo; echo "# aztfexport done."
