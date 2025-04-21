#!/bin/bash

# This pre-commit hook updates the minor version in Cargo.toml
# if there were changes in the src/rust_aztfexport_rename folder

# Path to the Cargo.toml file
CARGO_TOML="src/rust_aztfexport_rename/Cargo.toml"

# Check if any files in the src/rust_aztfexport_rename folder have changed
if git diff --cached --name-only | grep -q "^src/rust_aztfexport_rename/"; then
    echo "Detected changes in src/rust_aztfexport_rename. Incrementing version..."

    # Extract the current version from Cargo.toml
    CURRENT_VERSION=$(grep '^version' "$CARGO_TOML" | sed -E 's/version = "(.*)"/\1/')

    # Get the current date in YYYYMMDD format
    DATE=$(date +%Y%m%d)

    # Increment the patch version (e.g., 0.1.1 -> 0.1.2)
    NEW_VERSION=$(echo "$CURRENT_VERSION" | awk -F. '{printf "%d.%d.%d", $1, $2, $3+1}')

    # Append the date as build metadata (e.g., 0.1.2+YYYYMMDD)
    NEW_VERSION_WITH_DATE="${NEW_VERSION}+${DATE}"

    # Update the version in Cargo.toml
    sed -i.bak -E "s/^version = \".*\"/version = \"$NEW_VERSION_WITH_DATE\"/" "$CARGO_TOML" && rm "$CARGO_TOML.bak"

    echo "Updated version: $CURRENT_VERSION -> $NEW_VERSION"

    # Add the updated Cargo.toml to the commit
    git add "$CARGO_TOML"

    # Also add the Cargo.lock file to the commit
    if [ -f "src/rust_aztfexport_rename/Cargo.lock" ]; then
        sleep 1
        git add "src/rust_aztfexport_rename/Cargo.lock"
    fi
fi