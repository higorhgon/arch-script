#!/bin/bash

set -e

# Solicita senha sudo uma vez
sudo -v

echo "==> Listando snapshots atuais..."
sudo snapper list
echo ""
sudo snapper -c home list
echo ""

read -rp "Deseja remover TODOS os snapshots acima? [s/N] " confirm
if [[ ! "$confirm" =~ ^[sS]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
echo "==> Removendo snapshots de root..."
SNAPS_ROOT=$(sudo snapper list | awk 'NR>2 && $1 != "0" {print $1}' | tr '\n' ' ')
if [[ -n "$SNAPS_ROOT" ]]; then
    sudo snapper delete $SNAPS_ROOT
    echo "    Removidos: $SNAPS_ROOT"
else
    echo "    Nenhum snapshot encontrado."
fi

echo ""
echo "==> Removendo snapshots de home..."
SNAPS_HOME=$(sudo snapper -c home list | awk 'NR>2 && $1 != "0" {print $1}' | tr '\n' ' ')
if [[ -n "$SNAPS_HOME" ]]; then
    sudo snapper -c home delete $SNAPS_HOME
    echo "    Removidos: $SNAPS_HOME"
else
    echo "    Nenhum snapshot encontrado."
fi

echo ""
echo "==> Executando btrfs balance (metadata)..."
echo "    Isso pode demorar alguns minutos..."
sudo btrfs balance start -musage=70 /

echo ""
echo "==> Espaço livre após limpeza:"
sudo btrfs filesystem usage / | grep -E "Used:|Free"

echo ""
echo "Limpeza concluída!"
