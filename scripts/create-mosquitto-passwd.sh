#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONF_DIR="$BASE_DIR/mosquitto/config"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

mkdir -p "$CONF_DIR"

echo "[INFO] Criando passwd como root no container e corrigindo ownership..."
docker run --rm \
  -e HOST_UID="$HOST_UID" -e HOST_GID="$HOST_GID" \
  -v "$CONF_DIR:/mosquitto/config" \
  eclipse-mosquitto:2 sh -lc '
    mosquitto_passwd -c -b /mosquitto/config/passwd pzem 2007 && \
    chown "$HOST_UID:$HOST_GID" /mosquitto/config/passwd && \
    chmod 600 /mosquitto/config/passwd && \
    ls -l /mosquitto/config
  '

echo "[OK] Usuário 'pzem' criado com senha '2007' e permissões arrumadas."
