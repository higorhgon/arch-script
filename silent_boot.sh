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

# Comment out the "Loading Linux" echo message
sed -i '/echo.*Loading Linux.*grub_quote/s/^[[:space:]]*echo/\t#echo/' /etc/grub.d/10_linux

# Comment out the "Loading initial ramdisk" echo message  
sed -i '/echo.*Loading initial ramdisk.*grub_quote/s/^[[:space:]]*echo/\t#echo/' /etc/grub.d/10_linux

echo "✓ GRUB loading messages disabled"

# Update /etc/default/grub
echo "Updating GRUB configuration parameters..."

# Check if GRUB_CMDLINE_LINUX_DEFAULT exists and update it
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
    # Replace the existing line
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash systemd.show_status=false rd.udev.log_level=3"/' /etc/default/grub
    echo "✓ Updated existing GRUB_CMDLINE_LINUX_DEFAULT"
else
    # Add the line if it doesn't exist
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash systemd.show_status=false rd.udev.log_level=3"' >> /etc/default/grub
    echo "✓ Added GRUB_CMDLINE_LINUX_DEFAULT"
fi

if grep -q "#\s*GRUB_DISABLE_OS_PROBER=" /etc/default/grub; then
    # Uncomment and set to true
    sed -i 's/^#\s*GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
    echo "✓ Enabled GRUB_DISABLE_OS_PROBER"
fi

# Regenerate GRUB configuration
echo "Regenerating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg
echo "✓ GRUB configuration regenerated"

echo
echo "=== Configuration Complete! ==="
echo "Changes made:"
echo "• Disabled 'Loading Linux...' and 'Loading initial ramdisk...' messages"
echo "• Updated GRUB parameters for silent boot"
echo "• Regenerated GRUB configuration"
# echo
# echo "Backup files created:"
# echo "• /etc/grub.d/10_linux.backup.$(date +%Y%m%d_%H%M%S)"
# echo "• /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)"
echo
echo "Reboot to see the changes take effect."
