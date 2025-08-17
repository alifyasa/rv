#!/bin/bash
# install.sh - Complete installer for rv and dependencies

set -euo pipefail

# Output configuration - no colors, verbose but dense

# Script and dependency configuration
SCRIPT_NAME="rv.py"
TARGET_NAME="rv"
DEPENDENCIES=(
    "rclone:v1.70.3:https://downloads.rclone.org/v1.70.3/rclone-v1.70.3-linux-amd64.zip"
    "restic:v0.18.0:https://github.com/restic/restic/releases/download/v0.18.0/restic_0.18.0_linux_amd64.bz2"
    "resticprofile:v0.31.0:https://github.com/creativeprojects/resticprofile/releases/download/v0.31.0/resticprofile_0.31.0_linux_amd64.tar.gz"
)

# Function to check if binary exists
check_binary() {
    local binary_name="$1"
    local install_dir="$2"

    # Check if binary exists in install directory
    if [[ -x "$install_dir/$binary_name" ]]; then
        echo "$binary_name: already installed in $install_dir, skipping"
        return 0
    fi

    # Check if binary exists in PATH
    if command -v "$binary_name" >/dev/null 2>&1; then
        echo "$binary_name: found in PATH, skipping"
        return 0
    fi

    return 1
}

# Function to check if command needs sudo
needs_sudo() {
    local dir="$1"
    if [[ ! -w "$dir" ]]; then
        echo "sudo"
    fi
}

# Function to install dependencies
install_dependencies() {
    local install_dir="$1"

    echo "Installing dependencies: rclone v1.70.3, restic v0.18.0, resticprofile v0.31.0 to $install_dir"

    # Create temporary directory for downloads only if needed
    local temp_dir=""
    cleanup_temp() {
        if [[ -n "${temp_dir:-}" && -d "${temp_dir:-}" ]]; then
            rm -rf "$temp_dir"
        fi
    }
    trap cleanup_temp EXIT

    local sudo_cmd=$(needs_sudo "$install_dir")

    for dep in "${DEPENDENCIES[@]}"; do
        IFS=':' read -r binary_name version url <<< "$dep"

        if ! check_binary "$binary_name" "$install_dir"; then
            echo "$binary_name $version: downloading and installing"

            if [[ -z "$temp_dir" ]]; then
                temp_dir=$(mktemp -d)
                cd "$temp_dir"
            fi

            case "$binary_name" in
                "rclone")
                    curl -L "$url" -o rclone.zip
                    unzip -q rclone.zip
                    $sudo_cmd cp rclone-*-linux-amd64/rclone "$install_dir/"
                    $sudo_cmd chmod +x "$install_dir/rclone"
                    ;;
                "restic")
                    curl -L "$url" -o restic.bz2
                    bunzip2 restic.bz2
                    $sudo_cmd cp restic "$install_dir/"
                    $sudo_cmd chmod +x "$install_dir/restic"
                    ;;
                "resticprofile")
                    curl -L "$url" -o resticprofile.tar.gz
                    tar -xzf resticprofile.tar.gz
                    $sudo_cmd cp resticprofile "$install_dir/"
                    $sudo_cmd chmod +x "$install_dir/resticprofile"
                    ;;
            esac
            echo "$binary_name $version: installed successfully"
        fi
    done

    # Check if install directory is in PATH
    if [[ ":$PATH:" != *":$install_dir:"* ]]; then
        echo "WARNING: $install_dir not in PATH - add to ~/.bashrc or ~/.profile:"
        echo "export PATH=\"$install_dir:\$PATH\""
    fi
}

# Check if rv.py exists
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "Error: $SCRIPT_NAME not found in current directory"
    exit 1
fi

# Function to try installing rv to a directory
try_install() {
    local dir="$1"
    local target="$dir/$TARGET_NAME"

    if [ ! -d "$dir" ]; then
        return 1
    fi

    if [ ! -w "$dir" ]; then
        return 1
    fi

    # Install dependencies first
    install_dependencies "$dir"

    # Start rv installation process
    echo "rv: installing to writable PATH directory"

    # Check if rv already exists before overriding
    if command -v rv >/dev/null 2>&1; then
        echo "rv: found existing installation at $(which rv), overriding"
    fi

    # Then copy and make executable (override existing)
    cp "$SCRIPT_NAME" "$target"
    chmod +x "$target"

    echo "$TARGET_NAME: installed successfully to $dir"

    return 0
}

# Get PATH directories
IFS=':' read -ra PATH_DIRS <<< "$PATH"

# Preferred installation directories (in order of preference)
PREFERRED_DIRS=(
    "/usr/local/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
)

# Try preferred directories first
for dir in "${PREFERRED_DIRS[@]}"; do
    # Check if directory is in PATH
    for path_dir in "${PATH_DIRS[@]}"; do
        if [ "$dir" = "$path_dir" ]; then
            if try_install "$dir"; then
                exit 0
            fi
            break
        fi
    done
done

# If preferred dirs failed, try any writable directory in PATH
for dir in "${PATH_DIRS[@]}"; do
    # Skip if already tried
    skip=false
    for pref_dir in "${PREFERRED_DIRS[@]}"; do
        if [ "$dir" = "$pref_dir" ]; then
            skip=true
            break
        fi
    done

    if [ "$skip" = false ]; then
        if try_install "$dir"; then
            exit 0
        fi
    fi
done

# If all failed, show manual instructions
echo
echo "Automatic installation failed - manual installation required:"
echo "1. Choose a directory in your PATH:"
for dir in "${PATH_DIRS[@]}"; do
    echo "   - $dir"
done
echo
echo "2. Copy and make executable:"
echo "   sudo cp $SCRIPT_NAME /usr/local/bin/$TARGET_NAME"
echo "   sudo chmod +x /usr/local/bin/$TARGET_NAME"
echo
echo "3. Or install to user directory:"
echo "   mkdir -p ~/.local/bin"
echo "   cp $SCRIPT_NAME ~/.local/bin/$TARGET_NAME"
echo "   chmod +x ~/.local/bin/$TARGET_NAME"
echo "   # Add ~/.local/bin to PATH if not already there"
echo
echo "4. Then manually install dependencies to the same directory"
echo
exit 1
