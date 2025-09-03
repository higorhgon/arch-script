#!/bin/bash

# Script para instalar Nix e Home Manager no Arch Linux de forma automatizada.
# Baseado em guias oficiais. Rode com cuidado!

set -e # Para se houver erro em algum comando

echo "Iniciando instalação do Nix e Home Manager..."

# Passo 1: Instalar Nix (modo multi-usuário)
echo "Baixando e instalando Nix..."
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# Carrega as variáveis de ambiente do Nix (necessário para os próximos comandos)
source /etc/profile || source ~/.profile # Tenta carregar de /etc ou ~/

# Verifica se Nix foi instalado
if ! command -v nix &>/dev/null; then
    echo "Erro: Nix não foi instalado corretamente. Verifique logs acima."
    exit 1
fi
echo "Nix instalado com sucesso. Versão: $(nix --version)"

# Passo 2: Adicionar e atualizar canais Nix (unstable para pacotes recentes)
echo "Adicionando canal nixpkgs-unstable..."
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update
echo "Canais atualizados."

# Passo 3: Instalar Home Manager
echo "Adicionando canal do Home Manager (versão master)..."
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

echo "Instalando Home Manager..."
nix-shell '<home-manager>' -A install

# Verifica se Home Manager foi instalado
if ! command -v home-manager &>/dev/null; then
    echo "Erro: Home Manager não foi instalado corretamente. Verifique logs acima."
    exit 1
fi
echo "Home Manager instalado com sucesso."

# Passo 4: Criar um home.nix básico (se não existir)
HOME_MANAGER_CONFIG_DIR="$HOME/.config/home-manager"
HOME_NIX_FILE="$HOME_MANAGER_CONFIG_DIR/home.nix"

if [ ! -d "$HOME_MANAGER_CONFIG_DIR" ]; then
    mkdir -p "$HOME_MANAGER_CONFIG_DIR"
fi

if [ ! -f "$HOME_NIX_FILE" ]; then
    echo "Criando home.nix básico..."
    cat <<EOF >"$HOME_NIX_FILE"
{ config, pkgs, ... }:

{
  # Configurações básicas do Home Manager
  home.username = "$(whoami)";
  home.homeDirectory = "$HOME";

  # Defina a versão do estado para compatibilidade
  home.stateVersion = "24.05";  # Ajuste para a versão atual se necessário

  # Exemplo: Instale pacotes aqui (descomente e adicione)
  # home.packages = with pkgs; [
  #   htop
  #   git
  # ];

  # Ative programas ou configs (exemplo comentado)
  # programs.git.enable = true;
}
EOF
    echo "home.nix básico criado em $HOME_NIX_FILE. Edite-o para personalizar."
else
    echo "home.nix já existe. Pulando criação."
fi

# Ativar a configuração
echo "Aplicando configuração inicial do Home Manager..."
home-manager switch

echo "Instalação concluída! Agora você pode editar $HOME_NIX_FILE e rodar 'home-manager switch' para aplicar mudanças."
echo "Para mais ajuda, rode 'home-manager help' ou consulte a documentação oficial."
