mod clap;
mod res_map;
mod res_del;
mod res_rename;

use clap::Cli;
use res_map::read_resource_mapping;
use res_del::add_filters;

fn main() {
    // Parse command-line arguments
    let args = Cli::parse_args();

    // Apply optional filters passed on the CLI
    if !args.filter.is_empty() {
        add_filters(&args.filter);
    }

    // Read the source file
    let mut tf_resources = match read_resource_mapping(&args.src) {
        Ok(resource_mapping) => {
            println!(
                "Successfully read resource mapping from '{}': count={}",
                args.src,
                resource_mapping.len()
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
    // call delete_resources
    res_rename::delete_unwanted(&mut tf_resources);
    // call rename_resources
    res_rename::rename_resources(&mut tf_resources);

    // Write the resource mapping to the destination file
    match res_map::write_resource_mapping(&args.dst, &tf_resources) {
        Ok(_) => println!("Successfully wrote resource mapping to '{}'", args.dst),
        Err(e) => eprintln!("Failed to write resource mapping to '{}': {}", args.dst, e),
    }
}
