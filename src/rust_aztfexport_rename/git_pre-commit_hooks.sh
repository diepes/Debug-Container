#!/bin/bash

# This pre-commit hook updates the minor version in Cargo.toml and ./motd
# if there were changes in the src/rust_aztfexport_rename folder

# Path to the Cargo.toml file
CARGO_TOML="src/rust_aztfexport_rename/Cargo.toml"
CARGO_LOCK="" # Update at end if needed

# Check if any files in the src/rust_aztfexport_rename folder have changed
if git diff --cached --name-only | grep -q "^src/rust_aztfexport_rename/"; then
    echo "Detected changes in src/rust_aztfexport_rename. Incrementing version..."
    CARGO_LOCK="src/rust_aztfexport_rename/Cargo.lock"

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

    echo "Updated rust version: $CURRENT_VERSION -> $NEW_VERSION"

    # Add the updated Cargo.toml to the commit
    git add "$CARGO_TOML"

fi


# ./motd minor and date update
MOTD_FILE="motd"
README_FILE="README.md"

# Get current date in YYYY-MM-DD format
NEW_DATE=$(date +%Y-%m-%d)

# Extract the current version line
VERSION_LINE=$(grep -E "v[0-9]+\.[0-9]+\.[0-9]+ \([0-9]{4}-[0-9]{2}-[0-9]{2}\)" "$MOTD_FILE")

if [ -z "$VERSION_LINE" ]; then
    echo "Version line not found in $MOTD_FILE"
    exit 1
fi

# Extract just the version part (e.g., v0.3.1)
CURRENT_VERSION=$(echo "$VERSION_LINE" | grep -o "v[0-9]\+\.[0-9]\+\.[0-9]\+")

# Split version into major, minor, patch
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1 | tr -d 'v')
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

# Increment patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="v$MAJOR.$MINOR.$NEW_PATCH"

# Create the new version string
NEW_VERSION_STRING="$NEW_VERSION ($NEW_DATE)"

# Use sed with macOS-compatible syntax (empty backup extension)
sed -i '' "s|$CURRENT_VERSION ([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\})|$NEW_VERSION_STRING|g" "$MOTD_FILE"
git add "$MOTD_FILE"
sed -i '' "s|$CURRENT_VERSION ([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\})|$NEW_VERSION_STRING|g" "$README_FILE"
git add "$README_FILE"

echo "Updated motd version from $CURRENT_VERSION to $NEW_VERSION_STRING in $MOTD_FILE"
    
# Also add the Cargo.lock file to the commit
# It might be updated if the Cargo.toml file was modified
if [ "$CARGO_LOCK" != "" ]; then
        sleep 1
        git add "$CARGO_LOCK"
fi