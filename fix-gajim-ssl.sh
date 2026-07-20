#!/usr/bin/env bash
set -euo pipefail

SERVER="srv005.legisweb.com.br"
PORT="7443"
CERT_FILE="$HOME/.local/share/openfire-${SERVER}.crt"
BUNDLE_FILE="$HOME/.local/share/custom-ca-bundle.pem"
DESKTOP_SRC="/usr/share/applications/org.gajim.Gajim.desktop"
DESKTOP_DST="$HOME/.local/share/applications/org.gajim.Gajim.desktop"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[x]${NC} $*"; exit 1; }

echo "======================================"
echo "  Fix SSL - Gajim + Openfire"
echo "======================================"
echo

# Passo 1 — Baixar o certificado do servidor
info "Baixando certificado de ${SERVER}:${PORT}..."
mkdir -p "$(dirname "$CERT_FILE")"
openssl s_client -connect "${SERVER}:${PORT}" -showcerts </dev/null 2>/dev/null \
    | openssl x509 -outform PEM > "$CERT_FILE"

SUBJECT=$(openssl x509 -in "$CERT_FILE" -noout -subject 2>/dev/null)
NOT_AFTER=$(openssl x509 -in "$CERT_FILE" -noout -enddate 2>/dev/null)
info "Certificado capturado: ${SUBJECT}"
info "Validade: ${NOT_AFTER}"
echo

# Passo 2 — Adicionar ao bundle do certifi (Python)
info "Localizando bundle certifi do Python..."
CERTIFI_BUNDLE=$(python3 -c "import certifi; print(certifi.where())" 2>/dev/null || true)

if [[ -n "$CERTIFI_BUNDLE" && -f "$CERTIFI_BUNDLE" ]]; then
    if grep -q "srv005.legisweb.com.br" "$CERTIFI_BUNDLE" 2>/dev/null; then
        warn "Certificado já presente no bundle certifi, pulando."
    else
        info "Adicionando certificado ao certifi: $CERTIFI_BUNDLE"
        echo "" | sudo tee -a "$CERTIFI_BUNDLE" > /dev/null
        echo "# Openfire ${SERVER} (autoassinado)" | sudo tee -a "$CERTIFI_BUNDLE" > /dev/null
        sudo tee -a "$CERTIFI_BUNDLE" < "$CERT_FILE" > /dev/null
        info "Certificado adicionado ao certifi."
    fi
else
    warn "certifi não encontrado. Pulando este passo."
fi
echo

# Passo 3 — Criar bundle personalizado (sistema + openfire)
info "Criando bundle CA personalizado em ${BUNDLE_FILE}..."
SYSTEM_CA="/etc/ssl/certs/ca-certificates.crt"
if [[ ! -f "$SYSTEM_CA" ]]; then
    SYSTEM_CA="/etc/pki/tls/certs/ca-bundle.crt"
fi
if [[ -f "$SYSTEM_CA" ]]; then
    cat "$SYSTEM_CA" "$CERT_FILE" > "$BUNDLE_FILE"
    info "Bundle criado com CAs do sistema + certificado Openfire."
else
    warn "CA do sistema não encontrado. Bundle conterá apenas o certificado Openfire."
    cp "$CERT_FILE" "$BUNDLE_FILE"
fi
echo

# Passo 4 — Atualizar o .desktop do Gajim
info "Configurando lançador do Gajim..."
mkdir -p "$(dirname "$DESKTOP_DST")"

if [[ ! -f "$DESKTOP_SRC" ]]; then
    warn "Arquivo .desktop do Gajim não encontrado em ${DESKTOP_SRC}."
    warn "Crie um atalho manual com as variáveis de ambiente abaixo."
else
    cp "$DESKTOP_SRC" "$DESKTOP_DST"
    # Substituir a linha Exec= para incluir as variáveis de ambiente
    sed -i "s|^Exec=gajim|Exec=env SSL_CERT_FILE=${BUNDLE_FILE} REQUESTS_CA_BUNDLE=${BUNDLE_FILE} gajim|g" "$DESKTOP_DST"
    # Caso o Exec use outro formato (ex: gajim %u)
    sed -i "s|^Exec=env SSL_CERT_FILE=${BUNDLE_FILE} REQUESTS_CA_BUNDLE=${BUNDLE_FILE} gajim %U|Exec=env SSL_CERT_FILE=${BUNDLE_FILE} REQUESTS_CA_BUNDLE=${BUNDLE_FILE} gajim %U|g" "$DESKTOP_DST"
    info "Lançador atualizado em ${DESKTOP_DST}"
fi
echo

# Passo 5 — Fechar Gajim se estiver rodando
if pgrep -x gajim > /dev/null; then
    info "Encerrando Gajim..."
    pkill -x gajim || true
    sleep 1
fi

echo "======================================"
info "Concluído! Para testar, abra o Gajim pelo menu de aplicativos"
info "ou execute:"
echo
echo "  SSL_CERT_FILE=${BUNDLE_FILE} REQUESTS_CA_BUNDLE=${BUNDLE_FILE} gajim"
echo
warn "Nota: atualizações do pacote 'python-certifi' podem sobrescrever o passo 2."
warn "Nesse caso, rode este script novamente."
echo "======================================"
