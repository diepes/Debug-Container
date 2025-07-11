use crate::res_map::{Resource, ResourceMapping};

// function to rename resources in ResourceMapping, based on parsed values of resource_id updating resource_name.
pub fn rename_resources(resource_mapping: &mut ResourceMapping) {
    // Iterate through the resource mapping
    for (_k, r) in resource_mapping.iter_mut() {
        // Check if the resource ID matches
        match new_name(&r.resource_id) {
            Some(new_name) => {
                // Update the resource name
                r.resource_name = new_name;
            }
            None => {
                // Handle the case where the resource ID does not match
                println!("Resource ID does not match: {}", r.resource_id);
            }
        }
    }
}

pub fn new_name(resource: &str) -> Option<String> {
    // Extract the resource name from the resource ID
    let parts: Vec<&str> = resource.split('/').collect();
    // "resource_id": "/subscriptions/ed6ab5f7-5745-43f1-833b-28a7c06dc330/resourceGroups/z-azurearc-dev-windows-rg/providers/Microsoft.HybridCompute/machines/AKLADC04",
    //                 /1            /2                                   /3             /4                        /5        /6                      /7       /

    assert_eq!(
        parts[1], "subscriptions",
        "Expected first part to be 'subscriptions' not '{}' in '{}'",
        parts[1], resource
    );
    assert_eq!(
        parts[3], "resourceGroups",
        "Expected first part to be 'resourceGroups' not '{}' in '{}'",
        parts[3], resource
    );
    // test if parts[7] is one of a list of strings if len(parts) = 10
    let base_name: Option<&str>;
    if parts.len() > 9 {
        let valid_names = vec![
            "managedInstances",
            "networkSecurityGroups",
            "virtualMachines",
            "machines",           // for Arc machines
            "SqlServerInstances", // for Arc SQL Server instances
        ];
        assert!(
            valid_names.contains(&parts[7]),
            "assert! Invalid name: '{}' {}",
            parts[7],
            resource
        );
        base_name = Some(parts[8]);
    } else {
        base_name = None;
    }
    if parts.len() > 0 {
        let mut newname = parts[parts.len() - 1].to_string();
        // Replace all "." with "_"
        newname = newname.replace('.', "_");
        // Check if the resource name is not empty
        assert!(!newname.is_empty(), "Resource name is empty {}", resource);

        if let Some(base_name) = base_name {
            newname = format!("{}__{}", base_name, newname);
        }
        // Check that the resource name does not contain "." or "/"
        assert!(
            !newname.contains('.'),
            "Resource name contains '.' {}",
            newname
        );
        assert!(
            !newname.contains('/'),
            "Resource name contains '/' {}",
            newname
        );
        Some(newname)
    } else {
        None
    }
}

fn delete_check(_key: &str, resource: &Resource) -> bool {
    // Check if the resource type contains value in resource_types_to_delete
    let resource_types_to_delete: Vec<&str> = vec![
        // "Microsoft.Sql/managedInstances/databases",
        // "Microsoft.Sql/servers/databases",
        // "Microsoft.Sql/servers/elasticPools",
        "/securityRules/Microsoft.Sql-managedInstances_UseOnly_mi-",
        "Microsoft.Insights.VMDiagnosticsSettings",
        "/extensions/MDE.Windows",
        "/encryptionProtector/current",
        "/vulnerabilityAssessments/Default",
        "/securityAlertPolicies/Default",
    ];
    // Check if the resource type contains value in resource_types_to_delete
    if resource_types_to_delete
        .iter()
        .any(|&resource_type| resource.resource_id.contains(resource_type))
    {
        return true;
    }
    false
}

pub fn delete_unwanted(resources: &mut ResourceMapping) {
    // resource_types to delete
    // Iterate through the resource mapping
    let mut keys_to_remove = Vec::new();
    for (k, r) in resources.iter() {
        // Check if the resource type contains value in resource_types_to_delete
        if delete_check(&k, r) {
            // Collect the resource ID to be removed
            println!("Marking resource for deletion: {}", r.resource_id);
            keys_to_remove.push(r.resource_id.clone());
        }
    }
    // Remove the collected resources
    for key in keys_to_remove {
        resources.remove(&key);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_name() {
        // Example resource ID
        let resource_id = "/subscriptions/fcdddddd-1111-4444-9999-699999999998/resourceGroups/prod-laserfiche-rg/providers/Microsoft.Sql/managedInstances/z-prod-nl-sqlmi-lf-01/databases/LFWorkflow";

        // Expected new name
        let expected_name = "z-prod-nl-sqlmi-lf-01__LFWorkflow";

        // Call the function and assert the result
        let result = new_name(resource_id).expect("Failed to extract new name");
        assert_eq!(
            result, expected_name,
            "The new name did not match the expected value"
        );
    }
    fn read_test_resource_json(file_path: &str) -> ResourceMapping {
        // Load test data tests/202504_aztfexport_rg/aztfexportResourceMapping.json
        let file = std::fs::File::open(file_path).expect("Failed to open file");
        let reader = std::io::BufReader::new(file);
        let resource_mapping: ResourceMapping =
            serde_json::from_reader(reader).expect("Failed to parse JSON");
        resource_mapping
    }

    #[test]
    fn test_delete_unwanted_02() {
        // Load test data tests/202504_aztfexport_rg/aztfexportResourceMapping.json
        let file_path = "tests/202504_aztfexport_rg/aztfexportResourceMapping_test2.json";
        let resource_mapping: ResourceMapping = read_test_resource_json(file_path);
        // loop through the resource mapping and check if .resource_name_test is DELETE for all resources to be deleted
        for (_k, r) in resource_mapping.iter() {
            if delete_check(&r.resource_id, r) {
                assert_eq!(
                    r.resource_name_test,
                    Some("DELETE".to_string()),
                    "Test resource not marked for deletion: name: {}",
                    r.resource_name
                );
            }
        }
    }

    #[test]
    fn test_delete_rename_07() {
        // Load test data tests/202504_aztfexport_rg/aztfexportResourceMapping.json
        let file_path = "tests/202507_arc_rg/aztfexportResourceMapping.json";
        let resource_mapping: ResourceMapping = read_test_resource_json(file_path);
        // loop through the resource mapping and check if .resource_name_test is DELETE for all resources to be deleted
        for (_k, r) in resource_mapping.iter() {
            if delete_check(&r.resource_id, r) {
                assert_eq!(
                    r.resource_name_test,
                    Some("DELETE".to_string()),
                    "Test resource not marked for deletion: name: {}",
                    r.resource_name
                );
            }
            let new_name = new_name(&r.resource_id);
            assert!(
                new_name.is_some(),
                "New name is None for resource: {}",
                r.resource_id
            );
        }
    }

    #[test]
    fn test_new_name_file() {
        // Load test data tests/202504_aztfexport_rg/aztfexportResourceMapping.json
        let file_path = "tests/202504_aztfexport_rg/aztfexportResourceMapping_test2.json";
        let mut resource_mapping: ResourceMapping = read_test_resource_json(file_path);
        // Remove unwanted resources
        delete_unwanted(&mut resource_mapping);
        // Iterate through the resource mapping
        for (_k, r) in resource_mapping.iter() {
            let new_name = new_name(&r.resource_id);
            // Check if the resource ID matches
            match (new_name, r.resource_name_test.clone()) {
                // if we have both a rename and test name they should be the same
                (Some(gen_name), Some(test_name)) => {
                    // Update the resource name
                    assert_eq!(
                        gen_name, test_name,
                        "Resource name does not match: {} {} {}",
                        gen_name, test_name, r.resource_id
                    );
                }
                (None, Some(_)) => {
                    // Handle the case where the resource ID does not match
                    panic!(
                        "Resource ID does not match: {} {}",
                        r.resource_name, r.resource_id
                    );
                }
                (Some(nn), None) => {
                    panic!(
                        "Resource new name but no test_name provided:  new:{}, name:{}, id:{}",
                        nn, r.resource_name, r.resource_id
                    );
                }
                (None, None) => {
                    // Handle the case where the resource ID does not match
                    println!("Skip Resource ID with no test: {}", r.resource_id);
                }
            }
        }
    }
}
