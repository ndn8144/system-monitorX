#!/bin/bash

# =============================================================================
# System Monitor Script for Ubuntu and EndeavourOS
# Author: System Admin
# Version: 2.0
# Compatible: Ubuntu, EndeavourOS, Arch Linux, Debian-based distros
# =============================================================================

# Configuration
CONFIG_FILE="$HOME/.config/system-monitor.conf"
LOG_FILE="$HOME/.local/share/system-monitor.log"
ALERT_LOG="$HOME/.local/share/system-alerts.log"

# Default thresholds (can be overridden in config file)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMP_THRESHOLD=70
LOAD_THRESHOLD=2.0
SWAP_THRESHOLD=50

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Symbols
CHECK="✓"
WARNING="⚠"
ERROR="✗"
INFO="ℹ"

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$ALERT_LOG")"

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        create_default_config
    fi
}

# Create default configuration file
create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# System Monitor Configuration
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
TEMP_THRESHOLD=70
LOAD_THRESHOLD=2.0
SWAP_THRESHOLD=50
REFRESH_INTERVAL=5
ENABLE_NOTIFICATIONS=true
ENABLE_LOGGING=true
SHOW_PROCESSES=true
PROCESS_COUNT=10
EOF
    echo -e "${GREEN}${CHECK}${NC} Created default config at: $CONFIG_FILE"
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
    else
        DISTRO="unknown"
    fi
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$ENABLE_LOGGING" == "true" ]]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

# Alert function
send_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] ALERT: $message" >> "$ALERT_LOG"
    
    if [[ "$ENABLE_NOTIFICATIONS" == "true" ]]; then
        if command -v notify-send &> /dev/null; then
            notify-send "System Alert" "$message" -u critical
        fi
    fi
    
    log_message "ALERT" "$message"
}

# Get CPU usage
get_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}' | awk -F'us' '{print $1}')
    if [[ -z "$cpu_usage" ]]; then
        # Alternative method
        cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    fi
    printf "%.1f" "$cpu_usage"
}

# Get memory usage
get_memory_usage() {
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local percentage=$(echo "scale=1; $used * 100 / $total" | bc)
    echo "$percentage $used $total"
}

# Get swap usage
get_swap_usage() {
    local swap_info=$(free | grep Swap)
    local total=$(echo $swap_info | awk '{print $2}')
    if [[ "$total" -eq 0 ]]; then
        echo "0 0 0"
        return
    fi
    local used=$(echo $swap_info | awk '{print $3}')
    local percentage=$(echo "scale=1; $used * 100 / $total" | bc)
    echo "$percentage $used $total"
}

# Get disk usage
get_disk_usage() {
    df -h | grep -E '^/dev/' | while read line; do
        local device=$(echo $line | awk '{print $1}')
        local usage=$(echo $line | awk '{print $5}' | sed 's/%//')
        local mount=$(echo $line | awk '{print $6}')
        local used=$(echo $line | awk '{print $3}')
        local total=$(echo $line | awk '{print $2}')
        echo "$device $usage $mount $used $total"
    done
}

# Get load average
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
}

# Get system uptime
get_uptime() {
    uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}'
}

# Get network usage
get_network_usage() {
    local interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [[ -n "$interface" ]]; then
        local rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
        local tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
        echo "$interface $rx_bytes $tx_bytes"
    fi
}

# Get temperature (if available)
get_temperature() {
    local temp=""
    
    # Try different methods
    if command -v sensors &> /dev/null; then
        temp=$(sensors 2>/dev/null | grep -E "Core 0|Package id 0" | awk '{print $3}' | sed 's/+//;s/°C.*//' | head -n1)
    fi
    
    if [[ -z "$temp" ]] && [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        local temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
        temp=$(echo "scale=1; $temp_raw / 1000" | bc)
    fi
    
    echo "${temp:-N/A}"
}

# Get top processes
get_top_processes() {
    local count=${PROCESS_COUNT:-10}
    ps aux --sort=-%cpu | head -n $((count + 1))
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$(echo "scale=1; $bytes / 1024" | bc)KB"
    elif (( bytes < 1073741824 )); then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
    else
        echo "$(echo "scale=1; $bytes / 1073741824" | bc)GB"
    fi
}

# Get color based on threshold
get_threshold_color() {
    local value=$1
    local threshold=$2
    local warning_threshold=$((threshold - 10))
    
    if (( $(echo "$value >= $threshold" | bc -l) )); then
        echo "$RED"
    elif (( $(echo "$value >= $warning_threshold" | bc -l) )); then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# Display header
display_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                    SYSTEM MONITOR - $(date +'%Y-%m-%d %H:%M:%S')                    ${BLUE}║${NC}"
    echo -e "${BLUE}║${WHITE}                   Distribution: $DISTRO                              ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Display system info
display_system_info() {
    local cpu_usage=$(get_cpu_usage)
    local mem_data=($(get_memory_usage))
    local mem_usage=${mem_data[0]}
    local mem_used_kb=${mem_data[1]}
    local mem_total_kb=${mem_data[2]}
    
    local swap_data=($(get_swap_usage))
    local swap_usage=${swap_data[0]}
    local swap_used_kb=${swap_data[1]}
    local swap_total_kb=${swap_data[2]}
    
    local load_avg=$(get_load_average)
    local uptime=$(get_uptime)
    local temperature=$(get_temperature)
    
    # Convert memory to human readable
    local mem_used=$(format_bytes $((mem_used_kb * 1024)))
    local mem_total=$(format_bytes $((mem_total_kb * 1024)))
    local swap_used=$(format_bytes $((swap_used_kb * 1024)))
    local swap_total=$(format_bytes $((swap_total_kb * 1024)))
    
    # CPU
    local cpu_color=$(get_threshold_color "$cpu_usage" "$CPU_THRESHOLD")
    echo -e "${CYAN}${INFO} CPU Usage:${NC} ${cpu_color}${cpu_usage}%${NC}"
    
    # Check CPU threshold
    if (( $(echo "$cpu_usage >= $CPU_THRESHOLD" | bc -l) )); then
        send_alert "High CPU usage detected: ${cpu_usage}%"
    fi
    
    # Memory
    local mem_color=$(get_threshold_color "$mem_usage" "$MEMORY_THRESHOLD")
    echo -e "${CYAN}${INFO} Memory:${NC} ${mem_color}${mem_usage}%${NC} (${mem_used}/${mem_total})"
    
    # Check memory threshold
    if (( $(echo "$mem_usage >= $MEMORY_THRESHOLD" | bc -l) )); then
        send_alert "High memory usage detected: ${mem_usage}%"
    fi
    
    # Swap
    if [[ "$swap_total_kb" -gt 0 ]]; then
        local swap_color=$(get_threshold_color "$swap_usage" "$SWAP_THRESHOLD")
        echo -e "${CYAN}${INFO} Swap:${NC} ${swap_color}${swap_usage}%${NC} (${swap_used}/${swap_total})"
        
        if (( $(echo "$swap_usage >= $SWAP_THRESHOLD" | bc -l) )); then
            send_alert "High swap usage detected: ${swap_usage}%"
        fi
    else
        echo -e "${CYAN}${INFO} Swap:${NC} ${GREEN}Not configured${NC}"
    fi
    
    # Load Average
    local load_color=$GREEN
    if (( $(echo "$load_avg >= $LOAD_THRESHOLD" | bc -l) )); then
        load_color=$RED
        send_alert "High system load detected: $load_avg"
    fi
    echo -e "${CYAN}${INFO} Load Average:${NC} ${load_color}${load_avg}${NC}"
    
    # Temperature
    if [[ "$temperature" != "N/A" ]]; then
        local temp_color=$(get_threshold_color "$temperature" "$TEMP_THRESHOLD")
        echo -e "${CYAN}${INFO} Temperature:${NC} ${temp_color}${temperature}°C${NC}"
        
        if (( $(echo "$temperature >= $TEMP_THRESHOLD" | bc -l) )); then
            send_alert "High temperature detected: ${temperature}°C"
        fi
    fi
    
    # Uptime
    echo -e "${CYAN}${INFO} Uptime:${NC} ${GREEN}${uptime}${NC}"
    echo
}

# Display disk usage
display_disk_usage() {
    echo -e "${PURPLE}📊 DISK USAGE${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    
    get_disk_usage | while read disk_info; do
        local device=$(echo $disk_info | awk '{print $1}')
        local usage=$(echo $disk_info | awk '{print $2}')
        local mount=$(echo $disk_info | awk '{print $3}')
        local used=$(echo $disk_info | awk '{print $4}')
        local total=$(echo $disk_info | awk '{print $5}')
        
        local disk_color=$(get_threshold_color "$usage" "$DISK_THRESHOLD")
        printf "${CYAN}%-20s${NC} ${disk_color}%3s%%${NC} %-10s (%-8s/%-8s)\n" "$device" "$usage" "$mount" "$used" "$total"
        
        # Check disk threshold
        if (( usage >= DISK_THRESHOLD )); then
            send_alert "High disk usage on $mount: ${usage}%"
        fi
    done
    echo
}

# Display network info
display_network_info() {
    echo -e "${PURPLE}🌐 NETWORK${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    
    local net_info=$(get_network_usage)
    if [[ -n "$net_info" ]]; then
        local interface=$(echo $net_info | awk '{print $1}')
        local rx_bytes=$(echo $net_info | awk '{print $2}')
        local tx_bytes=$(echo $net_info | awk '{print $3}')
        
        local rx_formatted=$(format_bytes "$rx_bytes")
        local tx_formatted=$(format_bytes "$tx_bytes")
        
        echo -e "${CYAN}Interface:${NC} $interface"
        echo -e "${CYAN}RX Total:${NC} $rx_formatted"
        echo -e "${CYAN}TX Total:${NC} $tx_formatted"
    else
        echo -e "${YELLOW}No network interface found${NC}"
    fi
    echo
}

# Display top processes
display_top_processes() {
    if [[ "$SHOW_PROCESSES" == "true" ]]; then
        echo -e "${PURPLE}🔄 TOP PROCESSES (CPU)${NC}"
        echo "────────────────────────────────────────────────────────────────────"
        
        get_top_processes | while IFS= read -r line; do
            if [[ $line == *"USER"* ]]; then
                echo -e "${WHITE}$line${NC}"
            else
                # Color code based on CPU usage
                local cpu=$(echo "$line" | awk '{print $3}')
                local color=$GREEN
                if (( $(echo "$cpu >= 50" | bc -l) )); then
                    color=$RED
                elif (( $(echo "$cpu >= 20" | bc -l) )); then
                    color=$YELLOW
                fi
                echo -e "${color}$line${NC}"
            fi
        done
        echo
    fi
}

# Display system summary
display_summary() {
    echo -e "${PURPLE}📈 SUMMARY${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    
    local alerts_today=$(grep "$(date '+%Y-%m-%d')" "$ALERT_LOG" 2>/dev/null | wc -l)
    local log_size=$(du -h "$LOG_FILE" 2>/dev/null | awk '{print $1}' || echo "0B")
    
    echo -e "${CYAN}Alerts today:${NC} $alerts_today"
    echo -e "${CYAN}Log size:${NC} $log_size"
    echo -e "${CYAN}Config file:${NC} $CONFIG_FILE"
    echo -e "${CYAN}Alert log:${NC} $ALERT_LOG"
    echo
}

# Main monitoring function
monitor_system() {
    display_header
    display_system_info
    display_disk_usage
    display_network_info
    display_top_processes
    display_summary
    
    log_message "INFO" "System monitoring check completed"
}

# Continuous monitoring
continuous_monitor() {
    local interval=${REFRESH_INTERVAL:-5}
    
    echo -e "${GREEN}${CHECK}${NC} Starting continuous monitoring (refresh every ${interval}s)"
    echo -e "${YELLOW}${INFO}${NC} Press Ctrl+C to stop"
    echo
    
    while true; do
        monitor_system
        echo -e "${CYAN}Next refresh in ${interval} seconds...${NC}"
        sleep "$interval"
    done
}

# Show help
show_help() {
    cat << EOF
System Monitor Script - Ubuntu & EndeavourOS Compatible

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -c, --continuous        Run in continuous mode
    -i, --interval <sec>    Set refresh interval (default: 5)
    -q, --quiet             Suppress notifications
    --config               Show configuration file location
    --reset-config         Reset configuration to defaults
    --view-alerts          View recent alerts
    --clear-logs           Clear all logs

EXAMPLES:
    $0                      Run single check
    $0 -c                   Run continuous monitoring
    $0 -c -i 10             Run continuous with 10s interval
    $0 --view-alerts        Show recent alerts

FILES:
    Config: $CONFIG_FILE
    Log:    $LOG_FILE
    Alerts: $ALERT_LOG

EOF
}

# View recent alerts
view_alerts() {
    if [[ -f "$ALERT_LOG" ]]; then
        echo -e "${PURPLE}📢 RECENT ALERTS${NC}"
        echo "────────────────────────────────────────────────────────────────────"
        tail -20 "$ALERT_LOG"
    else
        echo -e "${GREEN}${CHECK}${NC} No alerts found"
    fi
}

# Clear logs
clear_logs() {
    read -p "Are you sure you want to clear all logs? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > "$LOG_FILE"
        > "$ALERT_LOG"
        echo -e "${GREEN}${CHECK}${NC} Logs cleared successfully"
    else
        echo -e "${YELLOW}${INFO}${NC} Operation cancelled"
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for bc (calculator)
    if ! command -v bc &> /dev/null; then
        missing_deps+=("bc")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}${WARNING}${NC} Missing dependencies: ${missing_deps[*]}"
        echo -e "${INFO} Install with:"
        
        case "$DISTRO" in
            "ubuntu"|"debian")
                echo "  sudo apt install ${missing_deps[*]}"
                ;;
            "arch"|"endeavouros"|"manjaro")
                echo "  sudo pacman -S ${missing_deps[*]}"
                ;;
            *)
                echo "  Please install: ${missing_deps[*]}"
                ;;
        esac
        echo
    fi
}

# Main script
main() {
    # Detect distribution
    detect_distro
    
    # Load configuration
    load_config
    
    # Check dependencies
    check_dependencies
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--continuous)
                CONTINUOUS=true
                shift
                ;;
            -i|--interval)
                REFRESH_INTERVAL="$2"
                shift 2
                ;;
            -q|--quiet)
                ENABLE_NOTIFICATIONS=false
                shift
                ;;
            --config)
                echo "Configuration file: $CONFIG_FILE"
                exit 0
                ;;
            --reset-config)
                rm -f "$CONFIG_FILE"
                create_default_config
                exit 0
                ;;
            --view-alerts)
                view_alerts
                exit 0
                ;;
            --clear-logs)
                clear_logs
                exit 0
                ;;
            *)
                echo -e "${RED}${ERROR}${NC} Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Run monitoring
    if [[ "$CONTINUOUS" == "true" ]]; then
        continuous_monitor
    else
        monitor_system
    fi
}

# Run main function with all arguments
main "$@"