use clap::Parser;

/// Command-line arguments for the application
#[derive(Parser, Debug)]
#[command(
    author,
    version = env!("CARGO_PKG_VERSION"), // Dynamically set version from Cargo.toml
    about = format!("rust_aztfexport_rename - A tool for renaming exported Azure Terraform resources\nVersion: {}", env!("CARGO_PKG_VERSION")),
    long_about = Some(concat!(
        "rust_aztfexport_rename - A tool for renaming resources\n",
        "Version: ", env!("CARGO_PKG_VERSION"), "\n\n",
        "This tool allows you to rename resources by specifying a source file and a destination file."
    )),
    next_line_help = true // Ensures help text is easier to read
)]
pub struct Cli {
    /// Source file path
    #[arg(short, long)]
    pub src: String,

    /// Destination file path
    #[arg(short, long)]
    pub dst: String,

    /// Exclude filter pattern (can be repeated)
    #[arg(short = 'f', long = "filter")]
    pub filter: Vec<String>,
}

impl Cli {
    /// Parses the command-line arguments and returns a `Cli` instance
    pub fn parse_args() -> Self {
        Cli::parse()
    }
}
