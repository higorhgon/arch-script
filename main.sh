#!/bin/bash

#HABILITA BLUETOOTH E SSH
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now sshd.service

#INSTALAÇÃO DE PACOTES
sudo pacman -Syu --needed --noconfirm \
    base-devel \
    git

cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

#LIMPA SOURCES
cd ~
rm -rf yay

yay -S --noconfirm \
    firefox \
    downgrade \
    tlrc \
    dosfstools \
    ntfs-3g \
    exfatprogs \
    kitty \
    eza \
    fzf \
    dracula-gtk-theme \
    bibata-cursor-theme-bin \
    papirus-icon-theme \
    noto-fonts-cjk \
    ttf-jetbrains-mono \
    ttf-nerd-fonts-symbols \
    networkmanager-openvpn \
    networkmanager-applet \
    blueman \
    plymouth \
    os-prober \
    docker \
    docker-compose \
    docker-buildx \
    neovim \
    yazi \
    npm \
    go \
    tree-sitter-cli \
    ripgrep \
    fish \
    atuin \
    starship

chsh -s /usr/bin/fish

#INSTALA OPENVPN COM DOWNGRADE
sudo downgrade openvpn

#CONFIG DOCKER
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable --now docker.service
newgrp docker

#REMOVE BLOAT
sudo pacman -R \
    gnome-tour \
    gnome-music \
    gnome-contacts \
    gnome-maps \
    gnome-software \
    gnome-console \
    epiphany \
    totem \
    vim

#SWAP ZRAM
echo "[zram0]" sudo >/etc/systemd/zram-generator.conf
echo "zram-size = ram * 4" sudo >>/etc/systemd/zram-generator.conf
echo "compression-algorithm = zstd" sudo >>/etc/systemd/zram-generator.conf

#SPLASH
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet splash\"/g' /etc/default/grub
sudo sed -i 's/HOOKS=(base udev/HOOKS=(base plymouth udev/g' /etc/mkinitcpio.conf

#GRUB
sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
