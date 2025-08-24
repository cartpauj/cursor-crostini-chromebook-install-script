#!/bin/bash

# Cursor AI Editor Installation Script for Crostini (Chrome OS Linux)
# This script automates the installation of Cursor text editor on Crostini
# Author: Generated with Claude Code
# License: MIT

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running on supported system
check_system() {
    print_status "Checking system compatibility..."
    
    if [[ ! -f /etc/debian_version ]]; then
        print_error "This script is designed for Debian-based systems (Crostini)"
        exit 1
    fi
    
    if [[ $(uname -m) != "x86_64" ]]; then
        print_error "This script only supports x86_64 architecture"
        exit 1
    fi
    
    print_success "System compatibility check passed"
}

# Function to update package lists and install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    sudo apt update
    
    # Install FUSE and other dependencies required for AppImages
    sudo apt install -y fuse libfuse2 wget curl
    
    print_success "Dependencies installed successfully"
}

# Function to get the latest Cursor download URL
get_latest_cursor_url() {
    print_status "Fetching latest Cursor version info..."
    
    # Get the latest version info from Cursor's official download API
    local download_info
    download_info=$(curl -s "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable")
    
    if [[ -z "$download_info" ]]; then
        print_error "Failed to fetch latest version information from Cursor API"
        exit 1
    fi
    
    # Parse the version and download URL
    CURSOR_VERSION=$(echo "$download_info" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    CURSOR_URL=$(echo "$download_info" | grep -o '"downloadUrl":"[^"]*"' | cut -d'"' -f4)
    
    if [[ -z "$CURSOR_VERSION" ]] || [[ -z "$CURSOR_URL" ]]; then
        print_error "Failed to parse version information from API response"
        exit 1
    fi
    
    print_success "Found Cursor version: $CURSOR_VERSION"
}

# Function to download Cursor AppImage
download_cursor() {
    print_status "Downloading Cursor AppImage..."
    print_status "Download URL: $CURSOR_URL"
    
    local temp_file="/tmp/cursor.AppImage"
    
    if ! wget "$CURSOR_URL" -O "$temp_file"; then
        print_error "Failed to download Cursor AppImage"
        exit 1
    fi
    
    # Verify the downloaded file
    if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
        print_error "Downloaded file is empty or doesn't exist"
        exit 1
    fi
    
    print_success "Cursor AppImage downloaded successfully"
    TEMP_APPIMAGE="$temp_file"
}

# Function to install Cursor to user directory
install_cursor() {
    print_status "Installing Cursor to ~/.local/bin/cursor.AppImage..."
    
    # Create user bin directory
    mkdir -p "$HOME/.local/bin"
    
    # Move to user location and make executable
    mv "$TEMP_APPIMAGE" "$HOME/.local/bin/cursor.AppImage"
    chmod +x "$HOME/.local/bin/cursor.AppImage"
    
    print_success "Cursor installed to ~/.local/bin/cursor.AppImage"
    print_success "✓ Auto-update enabled: Cursor can update itself in user directory"
}

# Function to extract and install icon
install_icon() {
    print_status "Extracting and installing Cursor icon..."
    
    # Create icons directory
    mkdir -p ~/.local/share/icons
    
    # Extract icon from AppImage
    local extract_dir="/tmp/cursor_extract_$$"
    mkdir -p "$extract_dir"
    cd "$extract_dir"
    
    "$HOME/.local/bin/cursor.AppImage" --appimage-extract usr/share/icons/hicolor/128x128/apps/cursor.png >/dev/null 2>&1
    
    if [[ -f "squashfs-root/usr/share/icons/hicolor/128x128/apps/cursor.png" ]]; then
        cp "squashfs-root/usr/share/icons/hicolor/128x128/apps/cursor.png" ~/.local/share/icons/cursor.png
        print_success "Cursor icon installed"
    else
        print_warning "Could not extract icon, using default"
        ICON_PATH="cursor"
    fi
    
    # Clean up
    cd ~
    rm -rf "$extract_dir"
    
    ICON_PATH="$HOME/.local/share/icons/cursor.png"
}

# Function to create desktop entry
create_desktop_entry() {
    print_status "Creating desktop entry..."
    
    # Create applications directory
    mkdir -p ~/.local/share/applications
    
    # Create desktop entry file
    cat > ~/.local/share/applications/cursor.desktop << EOF
[Desktop Entry]
Name=Cursor
Comment=AI-first code editor
Exec=$HOME/.local/bin/cursor.AppImage
Icon=$ICON_PATH
Type=Application
Categories=Development;TextEditor;
StartupNotify=true
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/javascript;application/json;text/css;text/html;text/xml;text/x-sql;text/x-ruby;
EOF
    
    # Update desktop database
    update-desktop-database ~/.local/share/applications 2>/dev/null || true
    
    print_success "Desktop entry created"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    if [[ ! -f "$HOME/.local/bin/cursor.AppImage" ]]; then
        print_error "Cursor AppImage not found at ~/.local/bin/cursor.AppImage"
        return 1
    fi
    
    if [[ ! -x "$HOME/.local/bin/cursor.AppImage" ]]; then
        print_error "Cursor AppImage is not executable"
        return 1
    fi
    
    if [[ ! -f ~/.local/share/applications/cursor.desktop ]]; then
        print_error "Desktop entry not found"
        return 1
    fi
    
    print_success "Installation verification passed"
}

# Function to show completion message
show_completion() {
    echo
    print_success "🎉 Cursor installation completed successfully!"
    echo
    echo -e "${GREEN}You can now:${NC}"
    echo "  • Launch Cursor from your applications menu"
    echo "  • Run from terminal: ~/.local/bin/cursor.AppImage"
    echo "  • Find it in the 'Development' category of your app launcher"
    echo
    echo -e "${BLUE}Cursor Version:${NC} $CURSOR_VERSION"
    echo -e "${BLUE}Installation Location:${NC} ~/.local/bin/cursor.AppImage"
    echo -e "${BLUE}Desktop Entry:${NC} ~/.local/share/applications/cursor.desktop"
    echo
    print_success "✓ Auto-update enabled: Cursor can update itself automatically"
    echo -e "${BLUE}Check for updates:${NC} Help → Check for Updates (or Ctrl+Shift+P → 'Update')"
    echo
    print_warning "Note: You may need to refresh your applications menu to see the icon"
}

# Function to handle cleanup on error
cleanup_on_error() {
    print_error "Installation failed. Cleaning up..."
    
    # Remove temporary files
    [[ -f "$TEMP_APPIMAGE" ]] && rm -f "$TEMP_APPIMAGE"
    
    # Remove partial installation
    [[ -f "$HOME/.local/bin/cursor.AppImage" ]] && rm -f "$HOME/.local/bin/cursor.AppImage"
    [[ -f ~/.local/share/applications/cursor.desktop ]] && rm -f ~/.local/share/applications/cursor.desktop
    [[ -f ~/.local/share/icons/cursor.png ]] && rm -f ~/.local/share/icons/cursor.png
    
    exit 1
}

# Main installation function
main() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                  Cursor AI Editor Installer                 ║${NC}"
    echo -e "${BLUE}║                     for Crostini (Chrome OS)                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Set up error handling
    trap cleanup_on_error ERR
    
    # Check for sudo access
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo access for installing system packages"
        print_status "You may be prompted for your password"
        sudo true
    fi
    
    # Run installation steps
    check_system
    install_dependencies
    get_latest_cursor_url
    download_cursor
    install_cursor
    install_icon
    create_desktop_entry
    verify_installation
    show_completion
}

# Run the main function
main "$@"
