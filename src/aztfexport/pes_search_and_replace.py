#!/usr/bin/env python3
# 2025-04-24 PESmit /!\ replace with rust ./src/rust_aztfexport_rename
# 2025-04-17 PESmit add python3 testing
# 2024-08-21 PESmit rename disks "Microsoft.Compute/disks/"
# 2024-05-02 PESmit rename VM, Nic, SqlDB, RG, snapshots, FW rules
import re

# Export the regex patterns
pattern_name = r'"resource_id":.+(/virtualMachines/|/Microsoft.Compute/snapshots/|Microsoft.Compute/disks/|/networkInterfaces/|/resourceGroups/|/Microsoft.Sql/servers/|/Microsoft.Network/privateEndpoints/|/networkSecurityGroups/)(?P<Name>[^"/]+)",'
pattern_ext = r'"resource_id":.+(/virtualMachines/|/Microsoft.Sql/servers/)(?P<Name>[^"/]+)(/extensions/|/firewallRules/|/databases/|/dataDisks/)(?P<Ext>[^"]+)",'

def search_and_replace(file_in, file_out, debug):
    with open(file_in, 'r') as fin:
        lines = fin.readlines()
    # e.g. 1 "resource_id": ".../virtualMachines/z-prod-bpapp-01": {"
    # e.g. 2 "resource_id": "/sub..../1../res..G./pr-rg/prov../Mic....Compute/virtualMachines/z-prod-bpapp-01/extensions/AzureMonitorWindowsAgent",
    # e.g. 2b "resource_id": "/su/.../providers/Microsoft.Compute/virtualMachines/z-prod-bpapp-01/extensions/MDE.Windows",
    # e.g. 3 .../Microsoft.Network/networkInterfaces/z-prod-wrobo-nic-03",
    # e.g. 4 .../servers/z-prod-blueprism-sql-01",
    # e.g. 5. "resource_id": "/subscriptions/11anonanon-08fe-4848-bbbb-anonanon1a/resourceGroups/prod-blueprism-rg"
    # e.g. 6. 		"resource_id": "/subscriptions/11anonanon-08fe-4848-bbbb-anonanon1a/resourceGroups/prod-blueprism-rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01",
    # e.g. 7 		"resource_id": "/subscriptions/11anonanon-08fe-4848-bbbb-anonanon1a/resourceGroups/prod-blueprism-rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01/firewallRules/twgadc-public-ips",
    # e.g. 8 "resource_id": "/subscriptions/23anonanon-4444-3434-6d6d-anonanon96/resourceGroups/dev-blueprism-rg/providers/Microsoft.Sql/servers/z-dev-blueprism-sql-01/databases/z-dev-blueprism-db",
    # e.g. 9 "resource_id": "/subscriptions/23anonanon-4444-3434-6d6d-anonanon96/resourceGroups/dev-blueprism-rg/providers/Microsoft.Network/privateEndpoints/blueprismshare",
    # e.g.10 "/subscriptions/7b897b3b-178e-4ec6-aeec-6bab809a5ead/resourceGroups/prod-rpt-rg/providers/Microsoft.Compute/disks/WHAKLVSQL02DRL-datadisk-01"
    # e.g.11 "/subscriptions/fcanonanon-1616-c7c7-d5d5-anonanonf8/resourceGroups/prod-laserfiche-rg/providers/Microsoft.Compute/virtualMachines/z-prod-wlfa-01/dataDisks/z-prod-wlfa-datadisk-01-0"
    # e.g.12 "/subscriptions/fcanonanon-1616-c7c7-d5d5-anonanonf8/resourceGroups/prod-laserfiche-rg/providers/Microsoft.Network/networkSecurityGroups/z-prod-nl-sqlmi-lf-nsg"
    # match pattern_ext 2nd part of resource_id
    new_lines = []
    for i, line in enumerate(lines):
        if '"resource_id"' in line:
            if debug: print("Found resource_id ..")
            match_name = re.search(pattern_name, line)
            match_ext = re.search(pattern_ext, line)
            if match_name or match_ext:
                if match_ext:
                    Name = match_ext.group(2).lower()
                    resource_name = Name + "_" + match_ext.group(4).lower().removeprefix(Name).removeprefix("-01").removeprefix("-").replace(".","-")
                    if debug: print(f"    ... match {resource_name=}")
                else:
                    resource_name = match_name.group(2).lower()
                # search through next 4 lines.
                for j in range(i, min(i + 4, len(lines))):
                    if '"resource_name"' in lines[j]:
                        if debug: print(f"    ... ... re.sub replace {resource_name=}")
                        lines[j] = re.sub(r'"resource_name": "([^"]+)"', f'"resource_name": "{resource_name}"', lines[j])
                # break

    with open(file_out, 'w') as fout:
        fout.write(''.join(lines))

file_in="aztf_out/aztfexportResourceMapping.json"
file_out="aztf_out/aztfexportResourceMapping.json.out"

if __name__ == "__main__":
    search_and_replace(file_in, file_out, debug=True)
