#!/usr/bin/env python3
# 2024-05-02 PESmit rename VM, Nic, SqlDB, RG, snapshots, FW rules
import re

def search_and_replace(file_in, file_out):
    with open(file_in, 'r') as fin:
        lines = fin.readlines()
    # e.g. 1 "resource_id": ".../virtualMachines/z-prod-bpapp-01": {"
    # e.g. 2 "resource_id": "/sub..../1../res..G./pr-rg/prov../Mic....Compute/virtualMachines/z-prod-bpapp-01/extensions/AzureMonitorWindowsAgent",
    # e.g. 2b "resource_id": "/su/.../providers/Microsoft.Compute/virtualMachines/z-prod-bpapp-01/extensions/MDE.Windows",
    # e.g. 3 .../Microsoft.Network/networkInterfaces/z-prod-wrobo-nic-03",
    # e.g. 4 .../servers/z-prod-blueprism-sql-01",
    # e.g. 5. "resource_id": "/subscriptions/1156dded-08fd-4348-bb97-e24158d3ad1a/resourceGroups/prod-blueprism-rg"
    # e.g. 6. 		"resource_id": "/subscriptions/1156dded-08fd-4348-bb97-e24158d3ad1a/resourceGroups/prod-blueprism-rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01",
    pattern_name = r'"resource_id":.+(/virtualMachines/|/Microsoft.Compute/snapshots/|/networkInterfaces/|/resourceGroups/|/Microsoft.Sql/servers/|/Microsoft.Network/privateEndpoints/)(?P<Name>[^"/]+)",'  # Regex pattern to capture virtual machine name
    # e.g. 7 		"resource_id": "/subscriptions/1156dded-08fd-4348-bb97-e24158d3ad1a/resourceGroups/prod-blueprism-rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01/firewallRules/twgadc-public-ips",
    # e.g. 8 "resource_id": "/subscriptions/23ca9af9-8e44-434c-86d5-aa67c56e6896/resourceGroups/dev-blueprism-rg/providers/Microsoft.Sql/servers/z-dev-blueprism-sql-01/databases/z-dev-blueprism-db",
    # e.g. 9 "resource_id": "/subscriptions/23ca9af9-8e44-434c-86d5-aa67c56e6896/resourceGroups/dev-blueprism-rg/providers/Microsoft.Network/privateEndpoints/blueprismshare",
	
    pattern_ext = r'"resource_id":.+(/virtualMachines/|/Microsoft.Sql/servers/)(?P<Name>[^"/]+)(/extensions/|/firewallRules/|/databases/)(?P<Ext>[^"]+)",'  # Regex pattern to capture virtual machine name
    new_lines = []
    for i, line in enumerate(lines):
        if '"resource_id"' in line:
            print("Found resource_id ..")
            match_name = re.search(pattern_name, line)
            match_ext = re.search(pattern_ext, line)
            if match_name or match_ext:
                if match_ext:
                    Name = match_ext.group(2).lower()
                    resource_name = Name + "_" + match_ext.group(4).lower().removeprefix(Name).removeprefix("-01").removeprefix("-").replace(".","-")
                    print(f"    ... match {resource_name=}")
                else:
                    resource_name = match_name.group(2).lower()
                # search through next 4 lines.
                for j in range(i, min(i + 4, len(lines))):
                    if '"resource_name"' in lines[j]:
                        print(f"    ... ... re.sub replace {resource_name=}")
                        lines[j] = re.sub(r'"resource_name": "([^"]+)"', f'"resource_name": "{resource_name}"', lines[j])
                # break

    with open(file_out, 'w') as fout:
        fout.write(''.join(lines))

file_in="aztf_out/aztfexportResourceMapping.json"
file_out="aztf_out/aztfexportResourceMapping.json.out"

search_and_replace(file_in, file_out)
