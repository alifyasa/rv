#!/bin/bash
# install.sh - Simple installer for rv

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script name
SCRIPT_NAME="rv.py"
TARGET_NAME="rv"

# Check if rv.py exists
if [ ! -f "$SCRIPT_NAME" ]; then
    echo -e "${RED}Error: $SCRIPT_NAME not found in current directory${NC}"
    exit 1
fi

# Function to try installing to a directory
try_install() {
    local dir="$1"
    local target="$dir/$TARGET_NAME"

    echo -e "${YELLOW}Trying to install to $dir...${NC}"

    if [ ! -d "$dir" ]; then
        echo -e "${RED}Directory $dir does not exist${NC}"
        return 1
    fi

    if [ ! -w "$dir" ]; then
        echo -e "${RED}No write permission to $dir${NC}"
        return 1
    fi

    # Copy and make executable
    cp "$SCRIPT_NAME" "$target"
    chmod +x "$target"

    echo -e "${GREEN}✅ Successfully installed $TARGET_NAME to $dir${NC}"
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

echo "Installing rv..."
echo

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
echo -e "${YELLOW}Trying other directories in PATH...${NC}"
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
echo -e "${RED}❌ Automatic installation failed${NC}"
echo
echo -e "${YELLOW}Manual installation:${NC}"
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
exit 1
