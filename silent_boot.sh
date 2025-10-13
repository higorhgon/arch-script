#!/bin/bash

# Silent Boot Configuration Script
# This script removes GRUB loading messages and configures silent boot parameters

set -e  # Exit on any error

echo "=== Silent Boot Configuration Script ==="
echo "This script will:"
echo "1. Modify /etc/grub.d/10_linux to remove loading messages"
echo "2. Update /etc/default/grub with silent boot and splashscreen parameters"
echo "3. Regenerate GRUB configuration"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Backup files
# echo "Creating backups..."
# cp /etc/grub.d/10_linux /etc/grub.d/10_linux.backup.$(date +%Y%m%d_%H%M%S)
# cp /etc/default/grub /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)
# echo "✓ Backups created"

# Modify /etc/grub.d/10_linux to remove echo messages
echo "Modifying /etc/grub.d/10_linux to remove loading messages..."

# Comment out echo lines that display loading messages in GRUB
# This matches the exact pattern: tab + echo + tab + '$(echo "$message" | grub_quote)'
sed -i 's/^[[:space:]]*echo[[:space:]]*'\''$(echo "$message" | grub_quote)'\''/#&/' /etc/grub.d/10_linux

echo "✓ GRUB loading messages disabled"

# Update /etc/default/grub
echo "Updating GRUB configuration parameters..."

# Check if GRUB_CMDLINE_LINUX_DEFAULT exists and update it
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
    # Replace the existing line with more comprehensive silent boot parameters
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=0 quiet splash systemd.show_status=false rd.udev.log_level=0 rd.systemd.show_status=false vga=current"/' /etc/default/grub
    echo "✓ Updated existing GRUB_CMDLINE_LINUX_DEFAULT"
else
    # Add the line if it doesn't exist
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=0 quiet splash systemd.show_status=false rd.udev.log_level=0 rd.systemd.show_status=false vga=current"' >> /etc/default/grub
    echo "✓ Added GRUB_CMDLINE_LINUX_DEFAULT"
fi

if grep -q "#\s*GRUB_DISABLE_OS_PROBER=" /etc/default/grub; then
    # Uncomment and set to true
    sed -i 's/^#\s*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
    echo "✓ Enabled GRUB_DISABLE_OS_PROBER"
fi

# Set GRUB timeout to 0 for faster boot (optional)
echo "Setting GRUB timeout to 0 for faster boot..."
if grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    echo "✓ Set GRUB_TIMEOUT to 0"
else
    echo 'GRUB_TIMEOUT=0' >> /etc/default/grub
    echo "✓ Added GRUB_TIMEOUT=0"
fi

# Ensure GRUB_TIMEOUT_STYLE is set to hidden
if grep -q "^GRUB_TIMEOUT_STYLE=" /etc/default/grub; then
    sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub
    echo "✓ Set GRUB_TIMEOUT_STYLE to hidden"
else
    echo 'GRUB_TIMEOUT_STYLE=hidden' >> /etc/default/grub
    echo "✓ Added GRUB_TIMEOUT_STYLE=hidden"
fi

# Regenerate GRUB configuration
echo "Regenerating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg
echo "✓ GRUB configuration regenerated"

echo
echo "=== Configuration Complete! ==="
echo "Changes made:"
echo "• Disabled 'Loading Linux...' and 'Loading initial ramdisk...' messages"
echo "• Updated GRUB parameters for complete silent boot (loglevel=0)"
echo "• Set GRUB timeout to 0 and timeout style to hidden"
echo "• Regenerated GRUB configuration"
# echo
# echo "Backup files created:"
# echo "• /etc/grub.d/10_linux.backup.$(date +%Y%m%d_%H%M%S)"
# echo "• /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)"
echo
echo "Reboot to see the changes take effect."
