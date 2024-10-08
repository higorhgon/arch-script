#!/bin/bash
if command -v zsh >/dev/null 2>&1
then 
    #HABILITA BLUETOOTH
    sudo systemctl enable --now bluetooth.service

    #INSTALAÇÃO DE PACOTES
    sudo pacman -Syu --needed --noconfirm \
        base-devel \
        git \
        dosfstools \
        ntfs-3g \
        exfatprogs \
        zsh-completions \
        tilix \
        duf \
        ncdu \
        tldr \
        noto-fonts-cjk \
        ttf-ms-fonts \
        gnome-browser-connector \
        docker \
        docker-compose \
        docker-buildx

    cd ~
    git clone https://aur.archlinux.org/snapd-glib.git
    cd snapd-glib
    makepkg -si --noconfirm

    cd ~
    git clone https://aur.archlinux.org/snapd.git
    cd snapd
    makepkg -si --noconfirm

    cd ~
    git clone https://aur.archlinux.org/libpamac-full.git
    cd libpamac-full
    makepkg -si --noconfirm

    cd ~
    git clone https://aur.archlinux.org/pamac-cli.git
    cd pamac-cli
    makepkg -si --noconfirm

    cd ~
    git clone https://aur.archlinux.org/pamac-all.git
    cd pamac-all
    makepkg -si --noconfirm

    cd ~
    git clone https://aur.archlinux.org/gnome-shell-extension-forge.git
    cd gnome-shell-extension-forge
    makepkg -si --noconfirm

    cd ~
    git clone https://gitlab.manjaro.org/packages/extra/bibata-cursor-theme.git
    cd bibata-cursor-theme
    makepkg -si --noconfirm

    cd ~
    rm -rf \
        gnome-shell-extension-forge \
        pamac-all \
        pamac-cli \
        libpamac-full \
        snapd \
        snapd-glib

    #INSTALACAO ATUIN (Ctrl + R)
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh\n
    atuin import auto
    sed -i 's/eval \"$(atuin init zsh)\"/eval \"$(atuin init zsh --disable-up-arrow)\"/g' .zshrc

    #CONFIG DOCKER
    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo systemctl enable --now docker.service

    #REMOVE BLOAT
    sudo pacman -R \
        gnome-tour \
        gnome-music \
        gnome-contacts \
        gnome-maps \
        gnome-weather \
        gnome-calendar \
        gnome-console \
        gnome-software \
        epiphany \
        totem \
        vim

    #SWAPFILE
    sudo swapoff /dev/zram0
    sudo zramctl /dev/zram0 --algorithm zstd --size "8GB"
    sudo mkswap -U clear /dev/zram0
    sudo swapon --discard --priority 100 /dev/zram0


    #OH MY ZSH
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions\n
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting\n
    sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' .zshrc


    #PACOTES FLATPAK
    flatpak install -y \
        io.github.realmazharhussain.GdmSettings \
        com.anydesk.Anydesk \
        com.microsoft.Edge \
        com.usebottles.bottles \
        org.gimp.GIMP \
        org.videolan.VLC \
        io.github.shiftey.Desktop \
        com.visualstudio.code \
        org.libreoffice.LibreOffice

    #RECARREGA CONFIGS ZSH
    source .zshrc
else 
    echo "Você não possui ZSH!!!"
    sudo pacman -S zsh

    echo "Inicie este script novamente"
    zsh
fi