#!/bin/bash

# Zen Browser theme sync for Omarchy
# Instala um template + hook de theme-set que regenera o userChrome.css do Zen
# a cada troca de tema do Omarchy (omarchy theme set <nome>).

set -e  # Exit on any error

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status()  { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

if [[ $EUID -eq 0 ]]; then
    print_error "Nao rode como root. Execute como usuario normal."
    exit 1
fi

if ! command -v omarchy &> /dev/null; then
    print_error "Comando 'omarchy' nao encontrado. Este script e exclusivo para Omarchy."
    exit 1
fi

if [[ ! -d "$HOME/.zen" ]]; then
    print_warning "~/.zen nao existe. Abra o Zen ao menos uma vez e rode de novo."
    exit 1
fi

TEMPLATE="$HOME/.config/omarchy/themed/zen-userchrome.css.tpl"
HOOK_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
HOOK="$HOOK_DIR/20-zen-theme"

mkdir -p "$(dirname "$TEMPLATE")" "$HOOK_DIR"

print_status "Passo 1: instalando template em $TEMPLATE"
cat > "$TEMPLATE" <<'TEMPLATE_EOF'
/* Gerado pelo Omarchy a partir do tema atual — nao editar manualmente */

:root {
  --omarchy-bg: {{ background }};
  --omarchy-fg: {{ foreground }};
  --omarchy-accent: {{ accent }};
  --omarchy-surface: {{ lighter_background }};
  --omarchy-surface-bright: {{ muted }};
  --omarchy-red: {{ red }};
  --omarchy-green: {{ green }};

  --zen-accent-color: {{ accent }} !important;
  --zen-border-color: {{ muted }} !important;
  --zen-themed-toolbar-color: {{ background }} !important;
  --zen-colors-primary: {{ accent }} !important;
  --zen-colors-secondary: {{ lighter_background }} !important;
  --zen-colors-tertiary: {{ background }} !important;
  --zen-dialog-background: {{ background }} !important;
  --zen-primary-color: {{ accent }} !important;
  --zen-element-separation: 0px !important;

  /* Menus e paineis */
  --arrowpanel-background: {{ background }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --arrowpanel-border-color: {{ lighter_background }} !important;
  --panel-background: {{ background }} !important;
  --panel-color: {{ foreground }} !important;
  --panel-border-color: {{ lighter_background }} !important;
  --panel-separator-color: {{ lighter_background }} !important;
  --panel-item-hover-bgcolor: {{ lighter_background }} !important;
  --panel-item-active-bgcolor: {{ muted }} !important;
  --toolbarbutton-hover-background: {{ lighter_background }} !important;
  --toolbarbutton-active-background: {{ muted }} !important;
}

/* ── Tab bar ── */
#TabsToolbar { background-color: var(--omarchy-bg) !important; }
.tabbrowser-tab .tab-background { background-color: transparent !important; }
.tabbrowser-tab[selected] .tab-background { background-color: var(--omarchy-surface) !important; border-radius: 8px !important; }
.tabbrowser-tab .tab-label { color: var(--omarchy-fg) !important; opacity: 0.6; }
.tabbrowser-tab[selected] .tab-label { color: var(--omarchy-fg) !important; opacity: 1; }

/* ── Toolbar / URL bar ── */
#nav-bar, #PersonalToolbar { background-color: var(--omarchy-bg) !important; border: none !important; }
#urlbar-background { background-color: var(--omarchy-surface) !important; border: 1px solid var(--omarchy-surface-bright) !important; border-radius: 8px !important; }
#urlbar:focus-within #urlbar-background { border-color: var(--omarchy-accent) !important; }
#urlbar .urlbar-input { color: var(--omarchy-fg) !important; }

/* ── URL bar dropdown ── */
.urlbarView-row[selected] .urlbarView-row-inner,
.urlbarView-row[selected] { background-color: var(--omarchy-accent) !important; color: var(--omarchy-bg) !important; }
.urlbarView-row[selected] .urlbarView-title,
.urlbarView-row[selected] .urlbarView-url,
.urlbarView-row[selected] .urlbarView-secondary-action { color: var(--omarchy-bg) !important; }

/* ── Zen sidebar ── */
#zen-sidebar-container, #zen-appcontent-navbar-container { background-color: var(--omarchy-bg) !important; }
#zen-main-app-wrapper, #zen-sidebar-top-buttons, .zen-sidebar-panel-wrapper { background-color: var(--omarchy-bg) !important; }
browser, #tabbrowser-tabpanels, .browserStack { background-color: var(--omarchy-bg) !important; }

/* ── Splitter / separator ── */
#zen-sidebar-splitter, #appcontent-splitter, .zen-sidebar-splitter { background-color: var(--omarchy-surface) !important; border: none !important; min-width: 1px !important; width: 1px !important; }

/* ── Borders & titlebar ── */
#main-window { border: 1px solid var(--omarchy-surface) !important; outline: none !important; }
#zen-appcontent-navbar-wrapper { border: none !important; outline: none !important; box-shadow: none !important; background-color: var(--omarchy-bg) !important; }
#titlebar { border: none !important; outline: none !important; box-shadow: none !important; background-color: var(--omarchy-bg) !important; }
.titlebar-buttonbox-container, .titlebar-buttonbox { border: none !important; outline: none !important; box-shadow: none !important; background: transparent !important; }
.titlebar-button { border: none !important; box-shadow: none !important; }

/* ── Pesquisa flutuante (urlbar expandida) ── */
:root #urlbar[breakout-extend] .urlbar-background {
  background-color: {{ background }} !important;
  outline-color: {{ lighter_background }} !important;
  box-shadow: 0 30px 140px -15px rgba(0, 0, 0, 0.6) !important;
}
:root #urlbar[breakout-extend] {
  --urlbarview-separator-color: {{ lighter_background }} !important;
  --urlbarview-background-color-hover: {{ lighter_background }} !important;
  --urlbar-box-hover-bgcolor: {{ lighter_background }} !important;
  --zen-toolbar-element-bg: {{ lighter_background }} !important;
  --zen-toolbar-element-bg-hover: {{ muted }} !important;
}
:root #urlbar[breakout-extend] .urlbarView-row:hover:not([selected]) .urlbarView-row-inner { background-color: {{ lighter_background }} !important; }
:root #urlbar[breakout-extend] .urlbarView-row[selected] .urlbarView-row-inner { background-color: {{ accent }} !important; color: {{ background }} !important; }
:root #urlbar[breakout-extend] .urlbarView-row[selected] .urlbarView-title,
:root #urlbar[breakout-extend] .urlbarView-row[selected] .urlbarView-url,
:root #urlbar[breakout-extend] .urlbarView-row[selected] .urlbarView-action { color: {{ background }} !important; }

/* ── Dropdown de <select> das paginas: segue o esquema de cor da pagina ── */
#ContentSelectDropdown {
  --panel-background: Field !important;
  --arrowpanel-background: Field !important;
  --panel-color: FieldText !important;
  --arrowpanel-color: FieldText !important;
  --panel-border-color: ThreeDShadow !important;
  --arrowpanel-border-color: ThreeDShadow !important;
  --panel-shadow-margin: 0px !important;
}
#ContentSelectDropdown menupopup::part(content) {
  padding: 0 !important;
  border-radius: 4px !important;
  background: Field !important;
  color: FieldText !important;
}
TEMPLATE_EOF

print_status "Passo 2: instalando hook em $HOOK"
cat > "$HOOK" <<'HOOK_EOF'
#!/bin/bash
# Copia o userChrome.css gerado pelo tema do Omarchy para o perfil padrao do Zen.
src="$HOME/.local/state/omarchy/current/theme/zen-userchrome.css"
[[ -f $src ]] || exit 0

# Perfil padrao: entrada Default= da secao [Install...] do installs.ini
profile=$(awk -F= '/^Default=/{print $2; exit}' "$HOME/.zen/installs.ini" 2>/dev/null)
[[ -n $profile && -d "$HOME/.zen/$profile" ]] || exit 0

dir="$HOME/.zen/$profile/chrome"
mkdir -p "$dir"
install -m 644 "$src" "$dir/userChrome.css"
HOOK_EOF
chmod +x "$HOOK"

print_status "Passo 3: habilitando userChrome.css nos perfis do Zen"
for prefs in "$HOME"/.zen/*/prefs.js; do
    [[ -f $prefs ]] || continue
    if ! grep -q 'toolkit.legacyUserProfileCustomizations.stylesheets", true' "$prefs"; then
        user_js="$(dirname "$prefs")/user.js"
        echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$user_js"
        print_status "Habilitado em $user_js"
    fi
done

print_status "Passo 4: gerando o tema atual"
omarchy theme refresh

echo
print_status "Pronto! Feche o Zen por completo (pkill -x zen-bin) e abra de novo."
print_warning "O Zen so le o userChrome.css ao iniciar: cada troca de tema exige reiniciar o navegador."
