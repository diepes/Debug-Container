use indexmap::IndexMap; // Import IndexMap
use serde::Deserialize;
use serde::Serialize; // Add Serialize for writing
use std::fs;
use std::io;

#[derive(Debug, Deserialize, Serialize)] // Add Serialize for writing
pub struct Resource {
    pub resource_id: String,
    pub resource_type: String,
    pub resource_name: String,
    #[serde(skip_serializing)] // Field used only for testing
    #[allow(dead_code)] // Suppress warning for unused field used in tests
    pub resource_name_test: Option<String>,
}

// Use IndexMap to preserve order
pub type ResourceMapping = IndexMap<String, Resource>;

/// Reads the JSON file and deserializes it into a `ResourceMapping`.
pub fn read_resource_mapping(file_path: &str) -> Result<ResourceMapping, io::Error> {
    // Read the file contents
    let file_content = fs::read_to_string(file_path)?;

    // Parse the JSON into the ResourceMapping type
    let resource_mapping: ResourceMapping = serde_json::from_str(&file_content)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;

    Ok(resource_mapping)
}

/// Writes the `ResourceMapping` to a JSON file, preserving the order.
pub fn write_resource_mapping(
    file_path: &str,
    resource_mapping: &ResourceMapping,
) -> Result<(), io::Error> {
    // Serialize the ResourceMapping to a JSON string
    let json_content = serde_json::to_string_pretty(resource_mapping)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;

    // Write the JSON string to the file
    fs::write(file_path, json_content)?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_read_resource_mapping() {
        let file_path = "./tests/202504_aztfexport_rg/aztfexportResourceMapping.json";
        let result = read_resource_mapping(file_path);

        assert!(
            result.is_ok(),
            "Failed to read resource mapping: {:?}",
            result
        );
        let resource_mapping = result.unwrap();

        // Check that the mapping contains expected keys
        assert!(resource_mapping.contains_key("/subscriptions/fcdddddd-1111-4444-9999-699999999998/resourceGroups/PROD-LASERFICHE-RG/providers/Microsoft.Compute/disks/z-prod-wlfa-datadisk-01-0"));
        assert!(resource_mapping.contains_key("/subscriptions/fcdddddd-1111-4444-9999-699999999998/resourceGroups/prod-laserfiche-rg/providers/Microsoft.Sql/managedInstances/z-prod-nl-sqlmi-lf-01/databases/LFDirectory"));

        // Validate the order of keys
        let keys: Vec<&String> = resource_mapping.keys().collect();
        assert_eq!(
            keys[0],
            "/subscriptions/fcdddddd-1111-4444-9999-699999999998/resourceGroups/PROD-LASERFICHE-RG/providers/Microsoft.Compute/disks/z-prod-wlfa-datadisk-01-0"
        );
        assert_eq!(
            keys[1],
            "/subscriptions/fcdddddd-1111-4444-9999-699999999998/resourceGroups/PROD-LASERFICHE-RG/providers/Microsoft.Compute/snapshots/z-prod-wlfa-datadisk-01-0_scsi_0_939383_GXMD_96cee2"
        );

        // Validate a specific resource
        let resource = resource_mapping.get("/subscriptions/fcdddddd-1111-4444-9999-699999999998/resourceGroups/PROD-LASERFICHE-RG/providers/Microsoft.Compute/disks/z-prod-wlfa-datadisk-01-0").unwrap();
        assert_eq!(resource.resource_name, "res-0");
        assert_eq!(resource.resource_type, "azurerm_managed_disk");
    }

    #[test]
    fn test_read_and_write_resource_mapping() {
        // Create a small test ResourceMapping
        let mut resource_mapping = ResourceMapping::new();
        resource_mapping.insert(
            "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Compute/disks/test-disk-01".to_string(),
            Resource {
                resource_id: "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Compute/disks/test-disk-01".to_string(),
                resource_type: "azurerm_managed_disk".to_string(),
                resource_name: "test-disk-01".to_string(),
                resource_name_test: None,
            },
        );
        resource_mapping.insert(
            "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Compute/snapshots/test-snapshot-01".to_string(),
            Resource {
                resource_id: "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Compute/snapshots/test-snapshot-01".to_string(),
                resource_type: "azurerm_snapshot".to_string(),
                resource_name: "test-snapshot-01".to_string(),
                resource_name_test: None,
            },
        );

        // Define test file paths
        let test_file_path = "./test_resource_mapping_deleteme.json";

        // Write the ResourceMapping to a file
        write_resource_mapping(test_file_path, &resource_mapping)
            .expect("Failed to write resource mapping");

        // Read the ResourceMapping back from the file
        let read_mapping =
            read_resource_mapping(test_file_path).expect("Failed to read resource mapping");

        // Verify the order is preserved
        let keys: Vec<&String> = read_mapping.keys().collect();
        assert_eq!(
            keys[0],
            "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Compute/disks/test-disk-01"
        );
        assert_eq!(
            keys[1],
            "/subscriptions/test/resourceGroups/test-rg/providers/Microsoft.Compute/snapshots/test-snapshot-01"
        );

        // Clean up the test file
        fs::remove_file(test_file_path).expect("Failed to delete test file");
    }
}
