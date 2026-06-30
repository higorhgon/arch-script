#!/bin/bash

set -e # Exit on any error
DEBUG=0

# GET DEBUG ARGUMENT
if [[ $1 == "--debug" ]]; then
    DEBUG=1
    echo "Debug mode enabled"
    echo $EUID
fi

# CHECK IF RUNNING AS ROOT
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Resolve the invoking user and their home directory
if [[ -z "$SUDO_USER" ]]; then
    echo "Error: Run this script with sudo, not directly as root."
    exit 1
fi
REAL_USER="$SUDO_USER"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")

if [ $DEBUG -ne 1 ]; then
    # GET USERNAME AND EMAIL FOR GIT
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    sudo -u "$REAL_USER" git config --global user.name "$git_username"
    sudo -u "$REAL_USER" git config --global user.email "$git_email"

    # GENERATE SSH KEY AND COPY TO CLIPBOARD FOR GITHUB
    sudo -u "$REAL_USER" mkdir -p "$USER_HOME/.ssh"
    sudo -u "$REAL_USER" chmod 700 "$USER_HOME/.ssh"
    if [[ -f "$USER_HOME/.ssh/id_rsa" ]]; then
        echo "SSH key already exists at $USER_HOME/.ssh/id_rsa. Skipping keygen."
    else
        # No passphrase (-N "") is used for convenience in an automated setup.
        # This is a security tradeoff: the key will not be protected by a passphrase.
        sudo -u "$REAL_USER" ssh-keygen -t rsa -N "" -C "$git_email" -f "$USER_HOME/.ssh/id_rsa"
    fi
    echo "Please add the copied SSH key to your GitHub account:"
    echo "Hold Ctrl (or Command) and click the link below to open it in your browser:"
    printf '\e]8;;https://github.com/settings/ssh/new\e\\https://github.com/settings/ssh/new\e]8;;\e\\n'
    if sudo -u "$REAL_USER" \
        WAYLAND_DISPLAY="${WAYLAND_DISPLAY}" \
        XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
        wl-copy < "$USER_HOME/.ssh/id_rsa.pub" 2>/dev/null; then
        echo "SSH public key copied to clipboard."
    else
        echo "Could not copy to clipboard. Your public key:"
        cat "$USER_HOME/.ssh/id_rsa.pub"
    fi

    # Wait for user to confirm they have added the SSH key or Escape to exit
    read -n 1 -s -r -p "Press any key to continue after adding the SSH key, or press Escape to exit..."
    if [[ $REPLY == $'\e' ]]; then
        echo
        echo "Exiting script."
        exit 1
    fi
fi

#ENABLE SERVICES
systemctl enable --now bluetooth.service
systemctl enable --now sshd.service

# UPDATE SYSTEM AND INSTALL DEV DEPENDENCIES
pacman -Syu --needed --noconfirm \
    base-devel \
    git

# INSTALL PARU
if command -v paru &>/dev/null; then
    echo "Paru is already installed"
else
    sudo -u "$REAL_USER" git clone https://aur.archlinux.org/paru-bin.git "$USER_HOME/paru-bin"
    sudo -u "$REAL_USER" bash -c "cd '$USER_HOME/paru-bin' && makepkg -si --noconfirm"
    rm -rf "$USER_HOME/paru-bin"
fi

# Function to install packages from a file
install_from_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        echo "Installing packages from $file..."
        # Remove comentários e linhas vazias, depois passa para o paru
        mapfile -t pkgs < <(grep -v '^#' "$file" | grep -v '^$')
        sudo -u "$REAL_USER" paru -S --noconfirm --needed "${pkgs[@]}"
    else
        echo "Warning: Package list $file not found."
    fi
}

# FILESYSTEMS
install_from_file "pkglist/filesystems.txt"

# ESSENTIALS
install_from_file "pkglist/essentials.txt"

# BOOTLOADER
install_from_file "pkglist/bootloader.txt"

# THEMES, ICONS, FONTS AND CURSORS
install_from_file "pkglist/themes.txt"

# TRAY APPLETS
install_from_file "pkglist/tray-applets.txt"

# CONTAINERS
install_from_file "pkglist/containers.txt"

# LANGUAGES
install_from_file "pkglist/languages.txt"

# INITIALIZE RUST
sudo -u "$REAL_USER" rustup default stable

# CHANGE SHELL TO FISH for the real user
chsh -s /usr/bin/fish "$REAL_USER"

# CONFIGURE DOCKER
getent group docker &>/dev/null || groupadd docker
usermod -aG docker "$REAL_USER"
systemctl enable --now docker.service
# Note: docker group membership takes effect on next login; newgrp is not used
# here because it spawns a blocking subshell that would prevent the rest of
# this script from executing.

# REMOVE BLOAT
if pacman -Qi dolphin &>/dev/null; then
    pacman -R --noconfirm dolphin
fi

# FIX para Impala
if command -v impala &>/dev/null; then
    systemctl enable iwd
fi

if command -v kanata &>/dev/null; then
    echo "Configuring uinput group for Kanata"
    echo "uinput" | tee /etc/modules-load.d/uinput.conf
    getent group uinput &>/dev/null || groupadd -r uinput
    usermod -aG uinput "$REAL_USER"
    echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | tee /etc/udev/rules.d/99-uinput.rules
    udevadm control --reload
    udevadm trigger
    modprobe -r uinput; modprobe uinput
fi

# SWAP ZRAM
echo "[zram0]" >/etc/systemd/zram-generator.conf
echo "zram-size = ram * 4" >>/etc/systemd/zram-generator.conf
echo "compression-algorithm = zstd" >>/etc/systemd/zram-generator.conf

plymouth-set-default-theme -R catppuccin-mocha

# GRUB
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet splash\"/g' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
sed -i 's|#GRUB_THEME=".*"|GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha/theme.txt"|g' /etc/default/grub

# mkinitcpio: add plymouth to HOOKS only if not already present
if grep -q 'HOOKS=(base udev' /etc/mkinitcpio.conf; then
    sed -i 's/HOOKS=(base udev/HOOKS=(base plymouth udev/g' /etc/mkinitcpio.conf
elif ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
    echo "Warning: Could not find expected HOOKS pattern in /etc/mkinitcpio.conf. Plymouth was not added automatically."
fi

grub-mkconfig -o /boot/grub/grub.cfg
