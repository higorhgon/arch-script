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

if [ $DEBUG -ne 1 ]; then
    # GET USERNAME AND EMAIL FOR GIT
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"

    # GENERATE SSH KEY AND COPY TO CLIPBOARD FOR GITHUB
    ssh-keygen -t rsa -C "$git_email"
    echo "Copying SSH key to clipboard. Please add it to your GitHub account."
    cat ~/.ssh/id_rsa.pub | wl-copy
    echo "Please add the copied SSH key to your GitHub account:"
    echo "Hold Ctrl (or Command) and click the link below to open it in your browser:"
    printf '\e]8;;https://github.com/settings/ssh/new\e\\https://github.com/settings/ssh/new\e]8;;\e\\n'
fi

# Wait for user to confirm they have added the SSH key or Escape to exit
read -n 1 -s -r -p "Press any key to continue after adding the SSH key, or press Escape to exit..."
if [[ $REPLY == $'\e' ]]; then
    echo
    echo "Exiting script."
    exit 1
fi

#ENABLE SERVICES
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now sshd.service

# UPDATE SYSTEM AND INSTALL DEV DEPENDENCIES
sudo pacman -Syu --needed --noconfirm \
    base-devel \
    git

# INSTALL PARU
if command -v paru &>/dev/null; then
    echo "Paru is already installed"
else
    cd ~ &&
        git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin && makepkg -si --noconfirm
    cd ~ && rm -rf paru-bin
fi

# Function to install packages from a file
install_from_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        echo "Installing packages from $file..."
        # Remove comentários e linhas vazias, depois passa para o paru
        grep -v '^#' "$file" | grep -v '^$' | xargs paru -S --noconfirm --needed
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
rustup default stable

# CHANGE SHELL TO FISH
chsh -s /usr/bin/fish

# CONFIGURE DOCKER
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable --now docker.service
newgrp docker

# REMOVE BLOAT
sudo pacman -R \
    dolphin

# FIX para Impala
if command -v impala &>/dev/null; then
    sudo systemctl enable iwd
fi

if command -v kanata &>/dev/null; then
    echo "Configuring uinput group for Kanata"
    echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf
    sudo groupadd -r uinput
    sudo usermod -aG uinput $USER
    echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/99-uinput.rules
    sudo udevadm control --reload
    sudo udevadm trigger
    sudo modprobe -r uinput; sudo modprobe uinput
fi

# SWAP ZRAM
echo "[zram0]" >/etc/systemd/zram-generator.conf
echo "zram-size = ram * 4" >>/etc/systemd/zram-generator.conf
echo "compression-algorithm = zstd" >>/etc/systemd/zram-generator.conf

sudo plymouth-set-default-theme -R catppuccin-mocha

# GRUB
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet splash\"/g' /etc/default/grub
sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
sudo sed -i 's|#GRUB_THEME=".*"|GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha/theme.txt"|g' /etc/default/grub
sudo sed -i 's/HOOKS=(base udev/HOOKS=(base plymouth udev/g' /etc/mkinitcpio.conf

sudo grub-mkconfig -o /boot/grub/grub.cfg
