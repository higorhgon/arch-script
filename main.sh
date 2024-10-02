#!/bin/bash
if command -v zsh >/dev/null 2>&1
then 
    #HABILITA BLUETOOTH
    sudo systemctl enable --now bluetooth.service

    #INSTALAÇÃO DE PACOTES
    sudo pacman -Syu --needed --noconfirm \
        base-devel \
        git \
        zsh-completions \
        tilix \
        duf \
        ncdu \
        tldr \
        noto-fonts-cjk \
        ttf-ms-fonts \
        docker \
        docker-compose \
        docker-buildx

    git clone https://aur.archlinux.org/snapd-glib.git
    cd snapd-glib
    makepkg -si --noconfirm

    git clone https://aur.archlinux.org/snapd.git
    cd snapd
    makepkg -si --noconfirm

    git clone https://aur.archlinux.org/libpamac-full.git
    cd libpamac-full
    makepkg -si --noconfirm

    git clone https://aur.archlinux.org/pamac-cli.git
    cd pamac-cli
    makepkg -si --noconfirm

    git clone https://aur.archlinux.org/pamac-all.git
    cd pamac-all
    makepkg -si --noconfirm

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
    flatpak install \
        io.github.realmazharhussain.GdmSettings \
        com.anydesk.Anydesk \
        com.microsoft.Edge \
        com.usebottles.bottles \
        org.gimp.GIMP \
        org.videolan.VLC

    #RECARREGA CONFIGS ZSH
    source .zshrc
else 
    echo "Você não possui ZSH!!!"
    sudo pacman -S zsh

    echo "Inicie este script novamente"
    zsh
fi