#!/bin/bash

# =============================================================================
# System Monitor Installation Script
# Compatible with Ubuntu and EndeavourOS
# =============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
CHECK="✓"
WARNING="⚠"
ERROR="✗"

SCRIPT_NAME="system-monitor"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config"
DESKTOP_DIR="$HOME/.local/share/applications"

echo -e "${GREEN}System Monitor Installation${NC}"
echo "=================================="

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        echo -e "${CHECK} Detected distribution: $DISTRO"
    else
        DISTRO="unknown"
        echo -e "${WARNING} Could not detect distribution"
    fi
}

# Install dependencies
install_dependencies() {
    echo -e "\n${YELLOW}Installing dependencies...${NC}"
    
    case "$DISTRO" in
        "ubuntu"|"debian"|"pop"|"mint")
            echo "Installing packages for Debian/Ubuntu-based system..."
            sudo apt update
            sudo apt install -y bc curl wget notify-osd libnotify-bin
            ;;
        "arch"|"endeavouros"|"manjaro")
            echo "Installing packages for Arch-based system..."
            sudo pacman -S --needed --noconfirm bc curl wget libnotify
            ;;
        "fedora")
            echo "Installing packages for Fedora..."
            sudo dnf install -y bc curl wget libnotify
            ;;
        *)
            echo -e "${WARNING} Unknown distribution. Please install manually: bc, curl, wget, libnotify"
            ;;
    esac
    
    echo -e "${GREEN}${CHECK}${NC} Dependencies installed"
}

# Create directories
create_directories() {
    echo -e "\n${YELLOW}Creating directories...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$HOME/.local/share"
    
    echo -e "${GREEN}${CHECK}${NC} Directories created"
}

# Install main script
install_script() {
    echo -e "\n${YELLOW}Installing system monitor script...${NC}"
    
    # Check if script exists in current directory
    if [[ -f "./system-monitorX.sh" ]]; then
        cp "./system-monitorX.sh" "$INSTALL_DIR/$SCRIPT_NAME"
    else
        echo -e "${ERROR} system-monitorX.sh not found in current directory"
        echo "Please ensure the script file is in the same directory as this installer"
        exit 1
    fi
    
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    echo -e "${GREEN}${CHECK}${NC} Script installed to $INSTALL_DIR/$SCRIPT_NAME"
}

# Create desktop entry
create_desktop_entry() {
    echo -e "\n${YELLOW}Creating desktop entry...${NC}"
    
    cat > "$DESKTOP_DIR/system-monitor.desktop" << EOF
[Desktop Entry]
Name=System Monitor
Comment=Advanced system monitoring tool
Exec=gnome-terminal -- $INSTALL_DIR/$SCRIPT_NAME -c
Icon=utilities-system-monitor
Terminal=true
Type=Application
Categories=System;Monitor;
Keywords=system;monitor;cpu;memory;disk;
EOF
    
    chmod +x "$DESKTOP_DIR/system-monitor.desktop"
    echo -e "${GREEN}${CHECK}${NC} Desktop entry created"
}

# Create systemd service (optional)
create_systemd_service() {
    echo -e "\n${YELLOW}Creating systemd user service...${NC}"
    
    local service_dir="$HOME/.config/systemd/user"
    mkdir -p "$service_dir"
    
    cat > "$service_dir/system-monitor-alerts.service" << EOF
[Unit]
Description=System Monitor Alert Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/$SCRIPT_NAME -c -q
Restart=always
RestartSec=30

[Install]
WantedBy=default.target
EOF
    
    # Create timer for periodic checks
    cat > "$service_dir/system-monitor-alerts.timer" << EOF
[Unit]
Description=System Monitor Alert Timer
Requires=system-monitor-alerts.service

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    echo -e "${GREEN}${CHECK}${NC} Systemd service created"
    echo -e "${YELLOW}To enable automatic monitoring:${NC}"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now system-monitor-alerts.timer"
}

# Add to PATH
add_to_path() {
    echo -e "\n${YELLOW}Adding to PATH...${NC}"
    
    local shell_rc=""
    case "$SHELL" in
        */bash)
            shell_rc="$HOME/.bashrc"
            ;;
        */zsh)
            shell_rc="$HOME/.zshrc"
            ;;
        */fish)
            shell_rc="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_rc="$HOME/.profile"
            ;;
    esac
    
    if ! grep -q "$INSTALL_DIR" "$shell_rc" 2>/dev/null; then
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$shell_rc"
        echo -e "${GREEN}${CHECK}${NC} Added $INSTALL_DIR to PATH in $shell_rc"
    else
        echo -e "${CHECK} PATH already configured"
    fi
}

# Create sample configuration
create_sample_config() {
    echo -e "\n${YELLOW}Creating sample configuration...${NC}"
    
    local config_file="$CONFIG_DIR/system-monitor.conf"
    
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << EOF
# System Monitor Configuration
# Thresholds (percentage)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMP_THRESHOLD=70
LOAD_THRESHOLD=2.0
SWAP_THRESHOLD=50

# Display settings
REFRESH_INTERVAL=5
SHOW_PROCESSES=true
PROCESS_COUNT=10

# Notification settings
ENABLE_NOTIFICATIONS=true
ENABLE_LOGGING=true

# Custom commands (optional)
# CUSTOM_CHECK_COMMAND=""
# CUSTOM_ALERT_COMMAND=""
EOF
        echo -e "${GREEN}${CHECK}${NC} Sample configuration created at $config_file"
    else
        echo -e "${CHECK} Configuration file already exists"
    fi
}

# Create aliases
create_aliases() {
    echo -e "\n${YELLOW}Creating useful aliases...${NC}"
    
    local alias_file="$HOME/.bash_aliases"
    
    if [[ ! -f "$alias_file" ]]; then
        touch "$alias_file"
    fi
    
    # Add aliases if they don't exist
    if ! grep -q "alias sysmon=" "$alias_file" 2>/dev/null; then
        cat >> "$alias_file" << EOF

# System Monitor aliases
alias sysmon='$SCRIPT_NAME'
alias sysmon-live='$SCRIPT_NAME -c'
alias sysmon-alerts='$SCRIPT_NAME --view-alerts'
alias sysmon-config='nano $CONFIG_DIR/system-monitor.conf'
EOF
        echo -e "${GREEN}${CHECK}${NC} Aliases added to $alias_file"
    else
        echo -e "${CHECK} Aliases already exist"
    fi
}

# Post-installation instructions
show_post_install() {
    echo -e "\n${GREEN}Installation completed successfully!${NC}"
    echo "============================================"
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $SCRIPT_NAME                    # Single check"
    echo "  $SCRIPT_NAME -c                # Continuous monitoring"
    echo "  $SCRIPT_NAME -c -i 10          # Custom interval"
    echo "  $SCRIPT_NAME --view-alerts     # View alerts"
    echo "  $SCRIPT_NAME --help            # Full help"
    echo
    echo -e "${YELLOW}Aliases (after restarting shell):${NC}"
    echo "  sysmon                         # Same as $SCRIPT_NAME"
    echo "  sysmon-live                    # Continuous monitoring"
    echo "  sysmon-alerts                  # View alerts"
    echo "  sysmon-config                  # Edit configuration"
    echo
    echo -e "${YELLOW}Files:${NC}"
    echo "  Script: $INSTALL_DIR/$SCRIPT_NAME"
    echo "  Config: $CONFIG_DIR/system-monitor.conf"
    echo "  Desktop: $DESKTOP_DIR/system-monitor.desktop"
    echo
    echo -e "${YELLOW}Optional:${NC}"
    echo "  • Restart your shell or run: source ~/.bashrc"
    echo "  • Enable background monitoring with systemd service"
    echo "  • Customize thresholds in config file"
    echo
    echo -e "${GREEN}${CHECK} Happy monitoring!${NC}"
}

# Main installation
main() {
    detect_distro
    install_dependencies
    create_directories
    install_script
    create_desktop_entry
    create_systemd_service
    add_to_path
    create_sample_config
    create_aliases
    show_post_install
}

# Run installation
main "$@"