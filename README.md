# System Monitor Script 🖥️

Một script monitoring hệ thống mạnh mẽ và toàn diện, tương thích với cả **Ubuntu** và **EndeavourOS** (và các distro Linux khác).

## ✨ Tính năng

### 📊 Monitoring Core
- **CPU Usage**: Theo dõi mức sử dụng CPU với cảnh báo threshold
- **Memory & Swap**: Giám sát RAM và swap usage
- **Disk Usage**: Kiểm tra dung lượng đĩa cứng trên tất cả mount points
- **Load Average**: Theo dõi system load
- **Temperature**: Hiển thị nhiệt độ CPU (nếu có sensor)
- **Network**: Thống kê lưu lượng mạng
- **Uptime**: Thời gian hoạt động của hệ thống

### 🔄 Top Processes
- Hiển thị top processes theo CPU usage
- Color-coded dựa trên mức độ sử dụng tài nguyên
- Configurable số lượng processes hiển thị

### 🚨 Alert System
- Tự động cảnh báo khi vượt ngưỡng threshold
- Desktop notifications (nếu có)
- Log alerts với timestamp
- Customizable thresholds cho từng metric

### 📝 Logging & Reporting
- Chi tiết system health logs
- Alert history tracking
- Export data để phân tích
- Configurable log levels

### 🎨 User Interface
- Colorful terminal output với icons
- Real-time continuous monitoring
- Clean, organized layout
- Progress bars và status indicators

## 🚀 Cài đặt

### Cách 1: Automatic Installation (Recommended)

```bash
# 1. Download scripts
wget https://raw.githubusercontent.com/ndn8144/system-monitorX.sh
wget https://raw.githubusercontent.com/ndn8144/install.sh

# 2. Make executable
chmod +x system-monitorX.sh install.sh

# 3. Run installer
./install.sh
```

### Cách 2: Manual Installation

```bash
# 1. Install dependencies
# Ubuntu/Debian:
sudo apt install bc curl wget libnotify-bin

# EndeavourOS/Arch:
sudo pacman -S bc curl wget libnotify

# 2. Create directories
mkdir -p ~/.local/bin ~/.config ~/.local/share

# 3. Copy script
cp system-monitorX.sh ~/.local/bin/system-monitor
chmod +x ~/.local/bin/system-monitor

# 4. Add to PATH
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

## 📖 Cách sử dụng

### Basic Commands

```bash
# Single check
system-monitor

# Continuous monitoring (refresh every 5s)
system-monitor -c

# Custom refresh interval
system-monitor -c -i 10

# Quiet mode (no notifications)
system-monitor -q

# View help
system-monitor --help
```

### Advanced Usage

```bash
# View recent alerts
system-monitor --view-alerts

# Reset configuration to defaults
system-monitor --reset-config

# Clear all logs
system-monitor --clear-logs

# Show config file location
system-monitor --config
```

### Aliases (after installation)

```bash
sysmon                 # Same as system-monitor
sysmon-live            # Continuous monitoring
sysmon-alerts          # View alerts
sysmon-config          # Edit configuration
```

## ⚙️ Configuration

Configuration file: `~/.config/system-monitor.conf`

```bash
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
```

### Customizing Thresholds

| Metric | Default | Description |
|--------|---------|-------------|
| CPU_THRESHOLD | 80% | CPU usage warning level |
| MEMORY_THRESHOLD | 85% | RAM usage warning level |
| DISK_THRESHOLD | 90% | Disk usage warning level |
| TEMP_THRESHOLD | 70°C | CPU temperature warning |
| LOAD_THRESHOLD | 2.0 | System load average warning |
| SWAP_THRESHOLD | 50% | Swap usage warning level |

## 🔧 Advanced Features

### Desktop Integration

Sau khi cài đặt, bạn có thể:
- Tìm "System Monitor" trong applications menu
- Pin vào taskbar để access nhanh
- Chạy từ desktop shortcut

### Systemd Service

Enable background monitoring:

```bash
# Enable automatic monitoring service
systemctl --user daemon-reload
systemctl --user enable --now system-monitor-alerts.timer

# Check service status
systemctl --user status system-monitor-alerts.service

# View service logs
journalctl --user -u system-monitor-alerts.service -f
```

### Log Files

| File | Purpose |
|------|---------|
| `~/.local/share/system-monitor.log` | General activity log |
| `~/.local/share/system-alerts.log` | Alert history |
| `~/.config/system-monitor.conf` | Configuration |

## 🎯 Use Cases

### 1. Development Environment Monitoring
```bash
# Monitor during compilation
sysmon-live &
make -j$(nproc)
```

### 2. Server Health Checks
```bash
# Quick health check
sysmon

# Continuous monitoring for servers
sysmon -c -i 30
```

### 3. Gaming Performance
```bash
# Monitor while gaming
sysmon -c -q  # Quiet mode, no notifications
```

### 4. Troubleshooting System Issues
```bash
# Check what's consuming resources
sysmon --view-alerts
sysmon -c -i 2  # High frequency monitoring
```

## 🐛 Troubleshooting

### Common Issues

**1. "bc command not found"**
```bash
# Ubuntu/Debian
sudo apt install bc

# EndeavourOS/Arch  
sudo pacman -S bc
```

**2. No temperature readings**
```bash
# Install lm-sensors (optional)
sudo apt install lm-sensors  # Ubuntu
sudo pacman -S lm_sensors    # Arch

# Detect sensors
sudo sensors-detect
```

**3. Notifications not working**
```bash
# Ubuntu/Debian
sudo apt install libnotify-bin

# EndeavourOS/Arch
sudo pacman -S libnotify
```

**4. Permission issues**
```bash
# Fix script permissions
chmod +x ~/.local/bin/system-monitor

# Fix PATH issues
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Debug Mode

Enable verbose logging:
```bash
# Edit config file
nano ~/.config/system-monitor.conf

# Set debug options
ENABLE_LOGGING=true
DEBUG_MODE=true
```

## 🔄 Updates

Update script:
```bash
# Download latest version
wget -O ~/.local/bin/system-monitor https://raw.githubusercontent.com/ndn8144/system-monitorX.sh
chmod +x ~/.local/bin/system-monitor

# Reset config if needed
system-monitor --reset-config
```

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional metrics (GPU, network interfaces)
- More distro support
- GUI version
- Mobile app integration
- Cloud monitoring features

## 📄 License

MIT License - Feel free to modify and distribute.

## 🆘 Support

- Check logs: `tail -f ~/.local/share/system-monitor.log`
- View alerts: `system-monitor --view-alerts`
- Reset config: `system-monitor --reset-config`
- GitHub Issues: [Report bugs here]

---

**Happy Monitoring!** 🎉

Tạo bởi: [Your Name]  
Compatible với: Ubuntu, EndeavourOS, Arch Linux, Debian, và nhiều distro khác