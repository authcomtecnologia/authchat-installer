#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Authchat — Bootstrap Installer
# Uso: curl -fsSL https://authchat-gateway.authcom.workers.dev/instalar | bash
# ─────────────────────────────────────────────────────────────────────────────

set -e

REPO_URL="https://github.com/authcomtecnologia/authchat-installer.git"
INSTALL_DIR="/tmp/authchat-installer"

RED='\033[0;31m'
NC='\033[0m'

echo "[Authcom Gateway] Iniciando instalador seguro..."

# ── Verifica e instala dependências básicas ──────────────────────────────────
for cmd in git curl unzip; do
  if ! command -v "$cmd" &>/dev/null; then
    apt-get install -y "$cmd" >/dev/null 2>&1 || {
      printf "${RED}[Authcom Gateway] Erro: nao foi possivel instalar '${cmd}'.${NC}\n"
      exit 1
    }
  fi
done

# ── Remove instalações anteriores e baixa a versão atual ────────────────────
rm -rf "$INSTALL_DIR"

echo "[Authcom Gateway] Validando chave e baixando pacotes..."
git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" >/dev/null 2>&1 || {
  printf "${RED}[Authcom Gateway] Erro ao baixar pacotes. Verifique a conexao com a internet.${NC}\n"
  exit 1
}

# ── Executa o instalador principal ──────────────────────────────────────────
# </dev/tty reconecta o stdin ao terminal real, necessário porque quando o
# script chega aqui via "curl | bash" o stdin está ocupado pela pipe e os
# comandos `read` dos menus receberiam EOF imediatamente, fechando o menu.
chmod +x "$INSTALL_DIR/install_primaria"
bash "$INSTALL_DIR/install_primaria" </dev/tty
