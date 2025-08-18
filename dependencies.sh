#!/bin/bash

# Bash strict mode
set -euo pipefail

# OODA Loop Implementation for Backup Tools Installation

echo "=== Backup Tools Installer ==="
echo "Installing: rclone v1.70.3, restic v0.18.0, resticprofile v0.31.0"
echo

# OBSERVE: Read current PATH and system state
echo "OBSERVE: Analyzing current system PATH..."
IFS=':' read -ra PATH_DIRS <<< "$PATH"
echo "Current PATH directories:"
for dir in "${PATH_DIRS[@]}"; do
    echo "  - $dir"
done
echo

# ORIENT: Define preferred installation paths (in order of preference)
PREFERRED_PATHS=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "/usr/local/bin"
    "/opt/bin"
)

echo "ORIENT: Preferred installation paths (in order):"
for path in "${PREFERRED_PATHS[@]}"; do
    echo "  - $path"
done
echo

# DECIDE: Find suitable installation directory
INSTALL_DIR=""
echo "DECIDE: Determining installation directory..."

# Check if any preferred path exists in current PATH
for preferred in "${PREFERRED_PATHS[@]}"; do
    for path_dir in "${PATH_DIRS[@]}"; do
        if [[ "$path_dir" == "$preferred" ]]; then
            echo "Found preferred path in PATH: $preferred"
            # Check if directory exists and is writable
            if [[ -d "$preferred" && -w "$preferred" ]]; then
                INSTALL_DIR="$preferred"
                echo "Selected installation directory: $INSTALL_DIR"
                break 2
            else
                echo "Warning: $preferred exists in PATH but is not writable or doesn't exist"
            fi
        fi
    done
done

# If no preferred path found in PATH, ask user
if [[ -z "$INSTALL_DIR" ]]; then
    echo "No preferred installation paths found in current PATH."
    echo "Available options:"
    echo "1. Create and use $HOME/.local/bin (recommended)"
    echo "2. Use /usr/local/bin (requires sudo)"
    echo "3. Specify custom path"

    read -p "Choose option (1-3): " choice

    case $choice in
        1)
            INSTALL_DIR="$HOME/.local/bin"
            mkdir -p "$INSTALL_DIR"
            echo "Created directory: $INSTALL_DIR"
            echo "Note: Add $INSTALL_DIR to your PATH if not already present"
            ;;
        2)
            INSTALL_DIR="/usr/local/bin"
            if [[ ! -w "$INSTALL_DIR" ]]; then
                echo "Warning: This will require sudo privileges"
            fi
            ;;
        3)
            read -p "Enter custom installation path: " custom_path
            INSTALL_DIR="$custom_path"
            mkdir -p "$INSTALL_DIR"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

echo "Final installation directory: $INSTALL_DIR"
echo

# ACT: Download and install tools
echo "ACT: Beginning installation process..."

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$TEMP_DIR"

# Function to check if command needs sudo
needs_sudo() {
    if [[ ! -w "$INSTALL_DIR" ]]; then
        echo "sudo"
    fi
}

SUDO_CMD=$(needs_sudo)

# Install rclone
echo "Installing rclone v1.70.3..."
curl -L "https://downloads.rclone.org/v1.70.3/rclone-v1.70.3-linux-amd64.zip" -o rclone.zip
unzip -q rclone.zip
$SUDO_CMD cp rclone-v1.70.3-linux-amd64/rclone "$INSTALL_DIR/"
$SUDO_CMD chmod +x "$INSTALL_DIR/rclone"
echo "✓ rclone installed"

# Install restic
echo "Installing restic v0.18.0..."
curl -L "https://github.com/restic/restic/releases/download/v0.18.0/restic_0.18.0_linux_amd64.bz2" -o restic.bz2
bunzip2 restic.bz2
$SUDO_CMD cp restic "$INSTALL_DIR/"
$SUDO_CMD chmod +x "$INSTALL_DIR/restic"
echo "✓ restic installed"

# Install resticprofile
echo "Installing resticprofile v0.31.0..."
curl -L "https://github.com/creativeprojects/resticprofile/releases/download/v0.31.0/resticprofile_0.31.0_linux_amd64.tar.gz" -o resticprofile.tar.gz
tar -xzf resticprofile.tar.gz
$SUDO_CMD cp resticprofile "$INSTALL_DIR/"
$SUDO_CMD chmod +x "$INSTALL_DIR/resticprofile"
echo "✓ resticprofile installed"

echo
echo "=== Installation Complete ==="
echo "All tools installed to: $INSTALL_DIR"
echo

# Verify installations
echo "Verifying installations:"
if command -v "$INSTALL_DIR/rclone" >/dev/null 2>&1; then
    echo "✓ rclone: $("$INSTALL_DIR/rclone" version | head -n1)"
else
    echo "⚠ rclone: Not found in PATH"
fi

if command -v "$INSTALL_DIR/restic" >/dev/null 2>&1; then
    echo "✓ restic: $("$INSTALL_DIR/restic" version)"
else
    echo "⚠ restic: Not found in PATH"
fi

if command -v "$INSTALL_DIR/resticprofile" >/dev/null 2>&1; then
    echo "✓ resticprofile: $("$INSTALL_DIR/resticprofile" version)"
else
    echo "⚠ resticprofile: Not found in PATH"
fi

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo
    echo "⚠ WARNING: $INSTALL_DIR is not in your PATH"
    echo "Add this line to your ~/.bashrc or ~/.profile:"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo
echo "Installation complete!"
