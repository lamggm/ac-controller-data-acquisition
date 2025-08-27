#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONF_DIR="$BASE_DIR/mosquitto/config"

mkdir -p "$CONF_DIR"

echo "[INFO] Criando arquivo passwd em $CONF_DIR"

docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$CONF_DIR:/mosquitto/config" \
  eclipse-mosquitto:2 sh -lc \
  'echo "2007" | mosquitto_passwd -c -p /mosquitto/config/passwd pzem'

chmod 600 "$CONF_DIR/passwd"

echo "[OK] Usuário 'pzem' criado com senha '2007'"