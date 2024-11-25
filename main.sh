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
        eza \
        fzf \
        tldr \
        noto-fonts-cjk \
        papirus-icon-theme \
        networkmanager-openvpn \
        plymouth \
        os-prober \
        nwg-look \
        docker \
        docker-compose \
        docker-buildx \
        neovim \
        npm \
        ripgrep \
        fish \
        atuin \
        starship

    cd ~
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    
    #LIMPA SOURCES
    cd ~
    rm -rf yay
    
    yay -S --noconfirm \
    	pamac-all \
    	nerdfonts-installer-bin \
    	bibata-cursor-theme-bin \
    	downgrade \
    	zen-browser-avx2-bin \
    	microsoft-edge-stable-bin \
    	visual-studio-code-bin
    
    #INSTALA OPENVPN COM DOWNGRADE
    sudo downgrade openvpn
    
    chsh -s /usr/bin/fish

    #INSTALACAO ATUIN (Ctrl + R)
    sed -i 's/eval \"$(atuin init zsh)\"/eval \"$(atuin init zsh --disable-up-arrow)\"/g' .zshrc
    source .zshrc
    atuin import auto
    
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
        epiphany \
        totem \
        vim 

    #SWAP ZRAM
    echo "[zram0]" sudo > /etc/systemd/zram-generator.conf
    echo "zram-size = ram * 4" sudo >> /etc/systemd/zram-generator.conf
    echo "compression-algorithm = zstd" sudo >> /etc/systemd/zram-generator.conf

    #SPLASH
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet splash\"/g' /etc/default/grub
    sudo sed -i 's/HOOKS=(base udev/HOOKS=(base plymouth udev/g' /etc/mkinitcpio.conf

    #GRUB
    sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/g' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    #OH MY ZSH
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    sed -i 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g' .zshrc
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' .zshrc

    #ICONES MS EDGE PARA PAPIRUS ICON THEME
    sudo cp /usr/share/icons/hicolor/16x16/apps/microsoft-edge.png /usr/share/icons/Papirus/16x16/apps
    sudo cp /usr/share/icons/hicolor/24x24/apps/microsoft-edge.png /usr/share/icons/Papirus/24x24/apps
    sudo cp /usr/share/icons/hicolor/32x32/apps/microsoft-edge.png /usr/share/icons/Papirus/32x32/apps
    sudo cp /usr/share/icons/hicolor/48x48/apps/microsoft-edge.png /usr/share/icons/Papirus/48x48/apps
    sudo cp /usr/share/icons/hicolor/64x64/apps/microsoft-edge.png /usr/share/icons/Papirus/64x64/apps
    sudo cp /usr/share/icons/hicolor/128x128/apps/microsoft-edge.png /usr/share/icons/Papirus/128x128/apps

    #PACOTES FLATPAK
    flatpak install -y \
        io.github.realmazharhussain.GdmSettings \
        com.anydesk.Anydesk \
        com.usebottles.bottles \
        org.gimp.GIMP \
        org.videolan.VLC \
        io.github.shiftey.Desktop \
        org.libreoffice.LibreOffice

    #RECARREGA CONFIGS ZSH
    source .zshrc

    #ICONE ags hyprland system-search-symbolic
else 
    echo "Você não possui ZSH!!!"
    sudo pacman -S --noconfirm zsh

    echo "Iniciando este script novamente"
    zsh -s $0
fi
