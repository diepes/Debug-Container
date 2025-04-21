mod clap;
mod resource_map;
mod resource_rename;

use clap::Cli;
use resource_map::read_resource_mapping;

fn main() {
    // Parse command-line arguments
    let args = Cli::parse_args();

    // Read the source file
    let mut tf_resources = match read_resource_mapping(&args.src) {
        Ok(resource_mapping) => {
            println!(
                "Successfully read resource mapping from '{}': {:?}",
                args.src, resource_mapping
            );

            // Here you can write the resource mapping to the destination file if needed
            println!("Destination file: {}", args.dst);
            resource_mapping
        }
        Err(e) => {
            eprintln!("Failed to read resource mapping from '{}': {}", args.src, e);
            panic!("Exiting due to error");
        }
    };
    // call rename_resources
    resource_rename::rename_resources(&mut tf_resources);

    // Write the resource mapping to the destination file
    match resource_map::write_resource_mapping(&args.dst, &tf_resources) {
        Ok(_) => println!("Successfully wrote resource mapping to '{}'", args.dst),
        Err(e) => eprintln!("Failed to write resource mapping to '{}': {}", args.dst, e),
    }
}
