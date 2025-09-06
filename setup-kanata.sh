#!/bin/bash

# Kanata Keyboard Remapper Setup Script for Arch Linux
# This script sets up Kanata with proper permissions and systemd service

set -e  # Exit on any error

echo "🚀 Setting up Kanata keyboard remapper for Arch Linux..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user."
   exit 1
fi

# Check if kanata is installed
if ! command -v kanata &> /dev/null; then
    print_warning "Kanata is not installed. Please install it first:"
    echo "  - From AUR: yay -S kanata-bin"
    echo "  - Or build from source: cargo install kanata"
    exit 1
fi

print_status "Step 1: Creating uinput group and adding user to groups..."

# Create uinput group
sudo groupadd -f uinput
print_status "Created uinput group (or it already exists)"

# Add current user to input and uinput groups
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER
print_status "Added $USER to input and uinput groups"

print_status "Step 2: Creating udev rules..."

# Create udev rules file
sudo tee /etc/udev/rules.d/99-input.rules > /dev/null << 'EOF'
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

print_status "Created /etc/udev/rules.d/99-input.rules"

print_status "Step 3: Reloading udev rules..."

# Reload udev rules
sudo udevadm control --reload-rules && sudo udevadm trigger
print_status "Reloaded udev rules"

print_status "Step 4: Creating systemd user service..."

# Create systemd user directory
mkdir -p ~/.config/systemd/user
print_status "Created systemd user directory"

# Create kanata systemd service
cat > ~/.config/systemd/user/kanata.service << 'EOF'
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin
Environment=DISPLAY=:0
Type=simple
ExecStart=/usr/bin/sh -c 'exec $$(which kanata) --cfg $${HOME}/.config/kanata/config.kbd'
Restart=no

[Install]
WantedBy=default.target
EOF

print_status "Created kanata systemd service file"

print_status "Step 5: Setting up systemd service..."

# Reload systemd daemon
systemctl --user daemon-reload
print_status "Reloaded systemd user daemon"

# Enable kanata service
systemctl --user enable kanata.service
print_status "Enabled kanata service"

print_status "Step 6: Creating kanata config directory..."

# Create kanata config directory
mkdir -p ~/.config/kanata
print_status "Created ~/.config/kanata directory"

# Check if config file exists
if [[ ! -f ~/.config/kanata/config.kbd ]]; then
    print_warning "Kanata config file doesn't exist. Creating a basic example..."
    
    cat > ~/.config/kanata/config.kbd << 'EOF'
;; Basic Kanata configuration example
;; Edit this file according to your needs
;; Documentation: https://github.com/jtroo/kanata

(defcfg
  process-unmapped-keys yes
)

(defsrc
  caps
)

(deflayer default
  esc
)
EOF
    
    print_warning "Created basic config at ~/.config/kanata/config.kbd"
    print_warning "Please edit this file according to your keyboard remapping needs!"
fi

print_status "Step 7: Testing service..."

# Try to start the service
if systemctl --user start kanata.service; then
    print_status "Started kanata service successfully"
    
    # Show service status
    echo ""
    print_status "Service status:"
    systemctl --user status kanata.service --no-pager -l
else
    print_error "Failed to start kanata service. Check the config file and logs."
    echo "Debug with: journalctl --user -u kanata.service -f"
fi

echo ""
print_status "✅ Kanata setup complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Edit your config: ~/.config/kanata/config.kbd"
echo "   2. Restart the service: systemctl --user restart kanata.service"
echo "   3. Check logs: journalctl --user -u kanata.service -f"
echo ""
print_warning "⚠️  You may need to log out and log back in for group changes to take effect!"
echo ""
echo "🔧 Useful commands:"
echo "   • Start:   systemctl --user start kanata.service"
echo "   • Stop:    systemctl --user stop kanata.service"
echo "   • Restart: systemctl --user restart kanata.service"
echo "   • Status:  systemctl --user status kanata.service"
echo "   • Logs:    journalctl --user -u kanata.service -f"
