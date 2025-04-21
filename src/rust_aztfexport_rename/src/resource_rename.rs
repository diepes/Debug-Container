use crate::resource_map::ResourceMapping;

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

    assert_eq!(
        parts[1], "subscriptions",
        "Expected first part to be 'subscriptions' not '{}' in '{}'",
        parts[0], resource
    );
    assert_eq!(
        parts[3], "resourceGroups",
        "Expected first part to be 'resourceGroups' not '{}' in '{}'",
        parts[3], resource
    );

    if parts.len() > 0 {
        Some(parts[parts.len() - 1].to_string())
    } else {
        None
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
        let expected_name = "LFWorkflow";

        // Call the function and assert the result
        let result = new_name(resource_id).expect("Failed to extract new name");
        assert_eq!(
            result, expected_name,
            "The new name did not match the expected value"
        );
    }
}
