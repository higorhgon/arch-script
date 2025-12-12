#!/bin/bash

# Script para configurar NetworkManager para usar iwd como backend
# Isso permite que tanto nmrs quanto Impala funcionem corretamente

set -e

echo "==> Configurando NetworkManager para usar iwd como backend..."

# Criar diretório de configuração se não existir
echo "==> Criando diretório de configuração..."
sudo mkdir -p /etc/NetworkManager/conf.d/

# Criar arquivo de configuração para usar iwd
echo "==> Criando arquivo de configuração wifi-backend.conf..."
sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf > /dev/null << 'EOF'
[device]
wifi.backend=iwd
EOF

echo "==> Arquivo criado:"
cat /etc/NetworkManager/conf.d/wifi-backend.conf

# Garantir que wpa_supplicant não está rodando
echo "==> Parando e desabilitando wpa_supplicant..."
sudo systemctl stop wpa_supplicant 2>/dev/null || true
sudo systemctl disable wpa_supplicant 2>/dev/null || true

# Garantir que iwd está habilitado
echo "==> Habilitando e iniciando iwd..."
sudo systemctl enable iwd
sudo systemctl start iwd

# Reiniciar NetworkManager
echo "==> Reiniciando NetworkManager..."
sudo systemctl restart NetworkManager

echo ""
echo "==> Configuração concluída!"
echo ""
echo "Agora tanto o nmrs quanto o Impala devem funcionar corretamente."
echo "Ambos usarão o iwd como backend para gerenciar WiFi."
echo ""
echo "Você pode testar com:"
echo "  - impala"
echo "  - nmrs"
echo "  - iwctl station wlan0 show"
