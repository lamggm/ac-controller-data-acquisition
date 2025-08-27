#!/bin/bash
set -euo pipefail

# Arruma donos/permissões dos volumes pra evitar teatro de horrores.
# Regras:
# - Node-RED: UID/GID 1000, chmod 775
# - MySQL:    UID/GID 999,  chmod 750 (não apaga nada)
# - Mosquitto data/log: UID/GID 1883, chmod 750
# - mosquitto/config/passwd: root:root 640 (arquivo sensível)
# - backups/ e rclone-config/: UID/GID 1000, chmod 775

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE_DIR"

echo "[INFO] Fixando permissões nos volumes (sem sudo, via Alpine no Docker)..."

# garante que as pastas existem
mkdir -p \
  mosquitto/config mosquitto/data mosquitto/log \
  mysql-data1 mysql-data2 \
  node-red-data1 node-red-data2 \
  backups rclone-config

# helper que roda um Alpine pra chown/chmod no host bind
fix_dir() {
  local path="$1" uid="$2" gid="$3" mode="$4"
  docker run --rm -v "$PWD/$path:/mnt" alpine sh -lc "chown -R ${uid}:${gid} /mnt && chmod -R ${mode} /mnt" >/dev/null
  echo "  ↳ $path => ${uid}:${gid} mode ${mode}"
}

# Node-RED
fix_dir "node-red-data1" 1000 1000 775
fix_dir "node-red-data2" 1000 1000 775

# MySQL
fix_dir "mysql-data1"    999  999  750
fix_dir "mysql-data2"    999  999  750

# Mosquitto data/log
fix_dir "mosquitto/data" 1883 1883 750
fix_dir "mosquitto/log"  1883 1883 750

# Mosquitto config (pastas legíveis, arquivo passwd mais rígido)
docker run --rm -v "$PWD/mosquitto/config:/mnt" alpine sh -lc '
  mkdir -p /mnt
  chmod 755 /mnt || true
  if [ -f /mnt/passwd ]; then
    chown root:root /mnt/passwd
    chmod 640 /mnt/passwd
  fi
' >/dev/null
echo "  ↳ mosquitto/config ajustado; passwd (se existir) é root:root 640"

# Backups e rclone-config
fix_dir "backups"        1000 1000 775
fix_dir "rclone-config"  1000 1000 775

echo "[OK] Permissões consertadas. Se ainda der 'EACCES', o karma tá atrasado."
