use once_cell::sync::Lazy;
use regex::RegexSet;
use std::sync::Mutex;

use crate::res_map::Resource;

// Patterns of resource_id substrings to delete; supports * and ? wildcards
pub static DELETE_PATTERNS: &[&str] = &[
    "/Microsoft.Network/networkSecurityGroups/*/securityRules/Microsoft.Sql-managedInstances_UseOnly_mi-",
    //"Microsoft.Insights.VMDiagnosticsSettings",
    "/providers/Microsoft.Sql/managedInstances/*/encryptionProtector/current",
    "/providers/Microsoft.Sql/managedInstances/*/vulnerabilityAssessments/Default",
    "/providers/Microsoft.Sql/managedInstances/*/securityAlertPolicies/Default",
    "/Microsoft.AzureArcData/SqlServerInstances/*/Databases/",
    "/providers/Microsoft.Compute/virtualMachines/*/extensions/MDE.Windows", // redundant
    "/providers/Microsoft.Compute/virtualMachines/*/extensions/*",
    "/providers/Microsoft.HybridCompute/machines/.*/extensions/*",
    "/providers/Microsoft.HybridCompute/machines/*/licenseProfiles/*",
    "/providers/Microsoft.AzureArcData/SqlServerInstances/*/AvailabilityGroups/*",
    // "/providers/Microsoft.AzureArcData/SqlServerInstances/*",
];

// Backing pattern list as strings (glob->regex transformed), initialized from defaults
static DELETE_PATTERNS_VEC: Lazy<Mutex<Vec<String>>> = Lazy::new(|| {
    let v: Vec<String> = DELETE_PATTERNS
        .iter()
        .map(|p| glob_to_regex_contains(p))
        .collect();
    Mutex::new(v)
});

// Compiled regex set built from DELETE_PATTERNS_VEC
static DELETE_REGEX_SET: Lazy<Mutex<RegexSet>> = Lazy::new(|| {
    let v = DELETE_PATTERNS_VEC.lock().expect("mutex poisoned");
    Mutex::new(RegexSet::new(v.clone()).expect("invalid delete patterns"))
});

// Add extra filter patterns from CLI (can be called once or multiple times)
pub fn add_filters(extra: &[String]) {
    if extra.is_empty() {
        return;
    }
    // Extend stored patterns
    {
        let mut v = DELETE_PATTERNS_VEC.lock().expect("mutex poisoned");
        v.extend(extra.iter().map(|s| glob_to_regex_contains(s)));
    }
    // Rebuild compiled set from updated patterns
    let v = DELETE_PATTERNS_VEC.lock().expect("mutex poisoned");
    let mut set_guard = DELETE_REGEX_SET.lock().expect("mutex poisoned");
    *set_guard = RegexSet::new(v.clone()).expect("invalid CLI filter patterns");
}

// Convert simple globs (* and ?) to regex fragments for substring matching
pub fn glob_to_regex_contains(glob: &str) -> String {
    let mut out = String::new();
    let mut prev_ch: Option<char> = None;
    for ch in glob.chars() {
        match ch {
            // Only expand to ".*" if previous character wasn't a dot
            '*' => {
                if matches!(prev_ch, Some('.')) {
                    out.push('*');
                } else {
                    out.push_str(".*");
                }
            }
            _ => out.push(ch),
        }
        prev_ch = Some(ch);
    }
    out
}

pub fn delete_check(_key: &str, resource: &Resource) -> bool {
    // True if any compiled pattern matches anywhere in the resource_id
    let set_guard = DELETE_REGEX_SET.lock().expect("mutex poisoned");
    set_guard.is_match(&resource.resource_id)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::res_map::ResourceMapping;
    use crate::res_rename::new_name;

    fn read_test_resource_json(file_path: &str) -> ResourceMapping {
        let file = std::fs::File::open(file_path).expect("Failed to open file");
        let reader = std::io::BufReader::new(file);
        serde_json::from_reader(reader).expect("Failed to parse JSON")
    }

    #[test]
    fn test_delete_unwanted_02() {
        let file_path = "tests/202504_aztfexport_rg/aztfexportResourceMapping_test2.json";
        let resource_mapping: ResourceMapping = read_test_resource_json(file_path);
        for (_k, r) in resource_mapping.iter() {
            if delete_check(&r.resource_id, r) {
                assert_eq!(
                    r.resource_name_test,
                    Some("DELETE".to_string()),
                    "Test resource not marked for deletion: name: {}",
                    r.resource_name
                );
            } else {
                assert_ne!(
                    r.resource_name_test,
                    Some("DELETE".to_string()),
                    "Resource marked for deletion incorrectly: name: {}",
                    r.resource_name
                );
            }
        }
    }

    #[test]
    fn test_delete_rename_07() {
        let file_path = "tests/202507_arc_rg/aztfexportResourceMapping.json";
        let resource_mapping: ResourceMapping = read_test_resource_json(file_path);
        for (_k, r) in resource_mapping.iter() {
            if delete_check(&r.resource_id, r) {
                assert_eq!(
                    r.resource_name_test,
                    Some("DELETE".to_string()),
                    "Test resource not marked for deletion: name: {}",
                    r.resource_name
                );
            }
            let nn = new_name(&r.resource_id);
            assert!(nn.is_some(), "New name is None for resource: {}", r.resource_id);
        }
    }
}
