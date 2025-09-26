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

# INSTALL YAY
if command -v yay &>/dev/null; then
    echo "Yay is already installed"
else
    cd ~ &&
        git clone https://aur.archlinux.org/yay-bin.git ||
        git clone --branch yay-bin --single-branch https://github.com/archlinux/aur.git yay-bin
    cd yay-bin && makepkg -si --noconfirm
    cd ~ && rm -rf yay-bin
fi

# FILESYSTEMS
yay -S --noconfirm \
    dosfstools \
    exfatprogs \
    ntfs-3g

# ESSENTIALS
yay -S --noconfirm \
    7zip \
    atuin \
    btop \
    bluetui \
    blueberry \
    cliphist \
    eza \
    fcitx5 \
    fcitx5-configtool \
    fcitx5-gtk \
    fcitx5-qt \
    fd \
    fish \
    fzf \
    ghostty \
    gnome-calculator \
    hyprland \
    hyprlock \
    hypridle \
    hyprshot \
    hyprpicker \
    hyprpolkit \
    impala \
    lazydocker \
    lazygit \
    less \
    lsof \
    neovim \
    opencode-bin \
    qt5ct \
    qt6ct \
    qt5-graphicaleffects \
    qt6-5compat \
    ripgrep \
    sddm-git \
    starship \
    stow \
    swaync \
    swww \
    tlrc \
    tmux \
    unzip \
    7zip \
    waybar \
    rofi \
    waypaper \
    waybar \
    wiremix \
    wl-clipboard \
    wl-clip-persist \
    xdg-desktop-portal-termfilechooser-hunkyburrito-git \
    xorg-xhost \
    yazi \
    zen-browser-bin

# BOOTLOADER
yay -S --noconfirm \
    os-prober \
    plymouth

# THEMES, ICONS, FONTS AND CURSORS
yay -S --noconfirm \
    bibata-cursor-theme-bin \
    catppuccin-mocha-grub-theme-git \
    dracula-gtk-theme \
    noto-fonts-cjk \
    papirus-icon-theme \
    plymouth-theme-catppuccin-mocha-git \
    catppuccin-sddm-theme-mocha \
    ttf-jetbrains-mono \
    ttf-jetbrains-mono-nerd \
    ttf-nerd-fonts-symbols \
    ttf-nerd-fonts-symbols-mono

# TRAY APPLETS
yay -S --noconfirm \
    blueman \
    network-manager-applet \
    networkmanager-openvpn

# CONTAINERS
yay -S --noconfirm \
    docker \
    docker-compose \
    docker-buildx

# LANGUAGES
yay -S --noconfirm \
    php \
    nodejs-lts-jod \
    go \
    rustup

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
