#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Authchat — Bootstrap Installer
# Uso: curl -fsSL https://authchat-gateway.authcom.workers.dev/instalar | bash
# ─────────────────────────────────────────────────────────────────────────────

set -e

REPO_URL="https://github.com/authcomtecnologia/authchat-installer.git"
INSTALL_DIR="/tmp/authchat-installer"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
printf "${GREEN}"
printf "##   ##  ##  ##  #####  ##  ##   ####  ##  ##   ##   ######\n"
printf "###  ##  ##  ##    ##   ##  ##  ##     ##  ##  #  #    ##\n"
printf "## # ##  ##  ##    ##   ######  ##     ######     #    ##\n"
printf "##  ###  ##  ##    ##   ##  ##  ##     ##  ##  #####   ##\n"
printf "##   ##   ####   #####  ##  ##   ####  ##  ##  #   #   ##\n"
printf "${NC}\n"
printf "  Gateway: https://authchat-gateway.authcom.workers.dev\n"
printf "  2025 @ Todos os direitos reservados - Authcom Tecnologia\n\n"

printf "${YELLOW}  Iniciando instalador Authchat...${NC}\n\n"

# ── Verifica e instala dependências básicas ──────────────────────────────────
for cmd in git curl unzip; do
  if ! command -v "$cmd" &>/dev/null; then
    printf "${YELLOW}  Instalando dependência: ${cmd}...${NC}\n"
    apt-get install -y "$cmd" >/dev/null 2>&1 || {
      printf "${RED}  ✗ Erro: não foi possível instalar '${cmd}'.${NC}\n"
      exit 1
    }
  fi
done

# ── Remove instalações anteriores e baixa a versão atual ────────────────────
rm -rf "$INSTALL_DIR"

printf "  Baixando scripts de instalação...\n"
git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1 || {
  printf "${RED}  ✗ Erro ao baixar instalador. Verifique a conexão com a internet.${NC}\n"
  exit 1
}

printf "${GREEN}  ✔ Instalador carregado com sucesso.${NC}\n\n"

# ── Executa o instalador principal ──────────────────────────────────────────
chmod +x "$INSTALL_DIR/install_primaria"
bash "$INSTALL_DIR/install_primaria"
