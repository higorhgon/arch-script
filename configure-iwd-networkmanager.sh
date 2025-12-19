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

[main]
# Desabilita gerenciamento automático de WiFi
# Isso impede que o NetworkManager reative o WiFi automaticamente
plugins=keyfile

[connection]
# Respeita o estado do WiFi quando manualmente desligado
wifi.powersave=ignore
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

# Habilitar e reiniciar NetworkManager
echo "==> Habilitando e reiniciando NetworkManager..."
sudo systemctl enable NetworkManager
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
