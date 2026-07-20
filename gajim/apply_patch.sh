#!/bin/bash
set -e

PATCH_FILE="$(dirname "$0")/gajim_feature.patch"
WORK_DIR="$(dirname "$0")/gajim-master_orig"
GAJIM_BASE=/usr/lib/python3.14/site-packages

echo "==> Copiando arquivos originais do Gajim instalado..."
mkdir -p "$WORK_DIR/gajim/common/modules"
mkdir -p "$WORK_DIR/gajim/common/storage/archive"

cp "$GAJIM_BASE/gajim/common/modules/mam.py"                  "$WORK_DIR/gajim/common/modules/mam.py"
cp "$GAJIM_BASE/gajim/common/modules/message.py"               "$WORK_DIR/gajim/common/modules/message.py"
cp "$GAJIM_BASE/gajim/common/storage/archive/storage.py"       "$WORK_DIR/gajim/common/storage/archive/storage.py"

echo "==> Aplicando patch..."
cd "$(dirname "$0")"
patch -p0 < "$PATCH_FILE"

echo "==> Copiando arquivos modificados para o Gajim instalado..."
sudo cp "$WORK_DIR/gajim/common/modules/mam.py"                "$GAJIM_BASE/gajim/common/modules/mam.py"
sudo cp "$WORK_DIR/gajim/common/modules/message.py"            "$GAJIM_BASE/gajim/common/modules/message.py"
sudo cp "$WORK_DIR/gajim/common/storage/archive/storage.py"    "$GAJIM_BASE/gajim/common/storage/archive/storage.py"

echo "==> Pronto! Reinicie o Gajim para aplicar as mudanças."
