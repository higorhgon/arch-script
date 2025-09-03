#!/bin/bash

# Script para configurar Kanata no Arch Linux com Hyprland
# Autor: Script automatizado para configuração de CapsLock tap/hold

set -e  # Para no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar se está rodando como usuário normal (não root)
if [ "$EUID" -eq 0 ]; then
    print_error "Este script deve ser executado como usuário normal, não como root!"
    print_info "Use: ./setup-kanata.sh"
    exit 1
fi

# Verificar se yay está instalado
if ! command -v yay &> /dev/null; then
    print_error "yay não encontrado! Por favor, instale o yay primeiro."
    print_info "Visite: https://github.com/Jguer/yay"
    exit 1
fi

print_info "Iniciando configuração do Kanata para o usuário: $USER"

# Instalar Kanata
print_info "Instalando Kanata via AUR..."
if yay -S kanata-bin --noconfirm; then
    print_success "Kanata instalado com sucesso!"
else
    print_error "Falha ao instalar Kanata!"
    exit 1
fi

# Criar diretório de configuração se não existir
CONFIG_DIR="$HOME/.config/kanata"
if [ ! -d "$CONFIG_DIR" ]; then
    print_info "Criando diretório de configuração: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    print_success "Diretório criado!"
else
    print_info "Diretório de configuração já existe."
fi

# Verificar se arquivo de configuração existe
CONFIG_FILE="$CONFIG_DIR/config.kbd"
if [ ! -f "$CONFIG_FILE" ]; then
    print_warning "Arquivo de configuração não encontrado em: $CONFIG_FILE"
    print_info "Por favor, crie o arquivo manualmente com a configuração desejada."
    print_info "Exemplo de conteúdo:"
    echo -e "${YELLOW}(defcfg"
    echo "  process-unmapped-keys yes"
    echo ")"
    echo ""
    echo "(defsrc"
    echo "  caps"
    echo ")"
    echo ""
    echo "(deflayer base"
    echo "  (tap-hold 150 200 esc lctl)"
    echo ")${NC}"
else
    print_success "Arquivo de configuração encontrado!"
fi

# Criar serviço systemd
print_info "Criando serviço systemd para o usuário: $USER"
SERVICE_FILE="/etc/systemd/system/kanata.service"

sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata
After=multi-user.target

[Service]
Environment=HOME=/home/$USER
ExecStart=/usr/bin/kanata --cfg /home/$USER/.config/kanata/config.kbd
Restart=on-failure
RestartSec=3
Type=simple
User=root

[Install]
WantedBy=multi-user.target
EOF

if [ $? -eq 0 ]; then
    print_success "Serviço systemd criado!"
else
    print_error "Falha ao criar serviço systemd!"
    exit 1
fi

# Recarregar systemd
print_info "Recarregando systemd daemon..."
sudo systemctl daemon-reload

# Habilitar serviço
print_info "Habilitando serviço kanata..."
if sudo systemctl enable kanata.service; then
    print_success "Serviço habilitado!"
else
    print_error "Falha ao habilitar serviço!"
    exit 1
fi

# Verificar se o arquivo de configuração existe antes de tentar iniciar
if [ -f "$CONFIG_FILE" ]; then
    # Testar configuração
    print_info "Testando configuração do Kanata..."
    if sudo kanata --cfg "$CONFIG_FILE" --check; then
        print_success "Configuração válida!"
        
        # Perguntar se quer iniciar o serviço agora
        echo
        read -p "Deseja iniciar o serviço Kanata agora? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Iniciando serviço kanata..."
            if sudo systemctl start kanata.service; then
                print_success "Serviço iniciado!"
                
                # Verificar status
                print_info "Status do serviço:"
                sudo systemctl status kanata.service --no-pager -l
            else
                print_error "Falha ao iniciar serviço!"
                print_info "Verifique os logs com: sudo journalctl -u kanata.service -f"
            fi
        else
            print_info "Serviço não iniciado. Para iniciar manualmente:"
            print_info "sudo systemctl start kanata.service"
        fi
    else
        print_warning "Configuração inválida! Corrija o arquivo antes de iniciar o serviço."
    fi
else
    print_warning "Arquivo de configuração não encontrado. Crie-o antes de iniciar o serviço."
fi

echo
print_success "Configuração do Kanata concluída!"
print_info "Comandos úteis:"
echo "  - Iniciar serviço: sudo systemctl start kanata.service"
echo "  - Parar serviço:   sudo systemctl stop kanata.service"
echo "  - Status:          sudo systemctl status kanata.service"
echo "  - Logs:            sudo journalctl -u kanata.service -f"
echo "  - Testar config:   sudo kanata --cfg ~/.config/kanata/config.kbd --check"

# Verificar se o grupo input existe e adicionar usuário se necessário
if getent group input > /dev/null; then
    if ! groups "$USER" | grep -q "\binput\b"; then
        print_info "Adicionando usuário $USER ao grupo 'input'..."
        sudo usermod -a -G input "$USER"
        print_warning "Você precisará fazer logout/login para que as mudanças de grupo tenham efeito."
    fi
fi

echo
print_info "Script finalizado para o usuário: $USER"
