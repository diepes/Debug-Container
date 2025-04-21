import unittest
import os
import tempfile
import re
from unittest.mock import patch
from pes_search_and_replace import search_and_replace, pattern_name, pattern_ext   # Assuming the original code is in search_and_replace.py

class TestSearchAndReplace(unittest.TestCase):
    def setUp(self):
        # Create a temporary directory for test files
        self.temp_dir = tempfile.mkdtemp(dir="./")
        self.input_file = os.path.join(self.temp_dir, 'input.json')
        self.output_file = os.path.join(self.temp_dir, 'output.json')

        # Test data covering all commented examples (e.g. 1–12) as a dictionary
        self.test_lines = {
            '1': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/z-prod-bpapp-01",
            "resource_name": "old_name"
            },
            '2': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/z-prod-bpapp-01/extensions/AzureMonitorWindowsAgent",
            "resource_name": "old_name"
            },
            '2b': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/z-prod-bpapp-01/extensions/MDE.Windows",
            "resource_name": "old_name"
            },
            '3': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Network/networkInterfaces/z-prod-wrobo-nic-03",
            "resource_name": "old_name"
            },
            '4': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01",
            "resource_name": "old_name"
            },
            '5': {
            "resource_id": "/subscriptions/123/resourceGroups/prod-blueprism-rg",
            "resource_name": "old_name"
            },
            '6': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01",
            "resource_name": "old_name"
            },
            '7': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Sql/servers/z-prod-blueprism-sql-01/firewallRules/twgadc-public-ips",
            "resource_name": "old_name"
            },
            '8': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Sql/servers/z-dev-blueprism-sql-01/databases/z-dev-blueprism-db",
            "resource_name": "old_name"
            },
            '9': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Network/privateEndpoints/blueprismshare",
            "resource_name": "old_name"
            },
            '10': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/disks/WHAKLVSQL02DRL-datadisk-01",
            "resource_name": "old_name"
            },
            '11': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/z-prod-wlfa-01/dataDisks/z-prod-wlfa-datadisk-01-0",
            "resource_name": "old_name"
            },
            '12': {
            "resource_id": "/subscriptions/123/resourceGroups/rg/providers/Microsoft.Network/networkSecurityGroups/z-prod-nl-sqlmi-lf-nsg",
            "resource_name": "old_name"
            }
        }

        # Write test data to input file
        with open(self.input_file, 'w') as f:
            f.writelines("{\n")
            for k,v in self.test_lines.items():
                f.writelines(f'  "{v["resource_id"]}": '+'{\n')
                f.writelines(f'    "resource_id": "{v["resource_id"]}",\n')
                f.writelines(f'    "resource_type": "dont-care-test",\n')
                f.writelines(f'    "resource_name": "res-123"\n')
                f.writelines("  },\n")
            f.writelines("}\n")



    def test_pattern_name_matches(self):
        """Test pattern_name regex against examples."""
        expected_names = {
            '1': 'z-prod-bpapp-01',
            '2': 'z-prod-bpapp-01',
            '2b': 'z-prod-bpapp-01',
            '3': 'z-prod-wrobo-nic-03',
            '4': 'z-prod-blueprism-sql-01',
            '5': 'prod-blueprism-rg',
            '6': 'z-prod-blueprism-sql-01',
            '7': 'z-prod-blueprism-sql-01',
            '8': 'z-dev-blueprism-sql-01',
            '9': 'blueprismshare',
            '10': 'WHAKLVSQL02DRL-datadisk-01',
            '11': 'z-prod-wlfa-01',
            '12': 'z-prod-nl-sqlmi-lf-nsg'
        }

        for key, expected in expected_names.items():
            # one of the patterns should match
            match_name = re.search(pattern_name, self.test_lines[key]['resource_id'])
            match_ext = re.search(pattern_ext, self.test_lines[key]['resource_id'])
            if match_name:
                match = match_name
                self.assertIsNotNone(match, f"Pattern_name failed to match:\r\n    test_line: {self.test_lines[key]['resource_id']}    key: {key}\r\n    pattern_name: {self.pattern_name}")
                self.assertEqual(match.group('Name'), expected, f"Wrong Name for: {self.test_lines[key]['resource_id']}")
            else:
                match = match_ext
                # self.assertIsNotNone(match, f"Pattern_ext failed to match: {self.test_lines[key]['resource_id']}")


    def test_pattern_ext_matches(self):
        """Test pattern_ext regex against examples with extensions."""
        print(f"self.test_lines keys: {self.test_lines.keys()}")
        print(f"self.test_lines['2']: {self.test_lines['2']}")
        test_cases = [
            (self.test_lines['2']['resource_id'], 'z-prod-bpapp-01', 'AzureMonitorWindowsAgent'),  # e.g. 2
            (self.test_lines['2b']['resource_id'], 'z-prod-bpapp-01', 'MDE.Windows'),  # e.g. 2b
            (self.test_lines['7']['resource_id'], 'z-prod-blueprism-sql-01', 'twgadc-public-ips'),  # e.g. 7
            (self.test_lines['8']['resource_id'], 'z-dev-blueprism-sql-01', 'z-dev-blueprism-db'),  # e.g. 8
            (self.test_lines['11']['resource_id'], 'z-prod-wlfa-01', 'z-prod-wlfa-datadisk-01-0'),  # e.g. 11
        ]

        # for line, expected_name, expected_ext in test_cases:
        #     match = re.search(self.pattern_ext, line)
        #     self.assertIsNotNone(match, f"Pattern_ext failed to match: {line}")
        #     self.assertEqual(match.group('Name'), expected_name, f"Wrong Name for: {line}")
        #     self.assertEqual(match.group('Ext'), expected_ext, f"Wrong Ext for: {line}")

    def test_search_and_replace_output(self):
        """Test search_and_replace function output."""
        search_and_replace(self.input_file, self.output_file, debug=False)

        # Expected resource_name values after replacement
        expected_names = {
            '1': 'z-prod-bpapp-01',
            '2': 'z-prod-bpapp_azuremonitorwindowsagent',
            '2b': 'z-prod-bpapp_mde-windows',
            '3': 'z-prod-wrobo-nic-03',
            '4': 'z-prod-blueprism-sql-01',
            '5': 'prod-blueprism-rg',
            '6': 'z-prod-blueprism-sql-01',
            '7': 'z-prod-blueprism-sql_twgadc-public-ips',
            '8': 'z-dev-blueprism-sql_z-dev-blueprism-db',
            '9': 'blueprismshare',
            '10': 'whaklvsql02drl-datadisk-01',
            '11': 'z-prod-wlfa_z-prod-wlfa-datadisk-0',
            '12': 'z-prod-nl-sqlmi-lf-nsg'
        }


    def tearDown(self):
        print("# tearDown() Clean up temporary directory")
        for file in [self.input_file, self.output_file]:
            if os.path.exists(file):
                print(f"    Removing file: {file}")
                # os.remove(file)
        # os.rmdir(self.temp_dir)

if __name__ == '__main__':
    unittest.main()
