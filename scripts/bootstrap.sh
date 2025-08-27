#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE_DIR"

# 0) garantir executável
chmod +x scripts/create-mosquitto-passwd.sh \
         scripts/create-mysql-users.sh \
         scripts/reset-mysql-schemas.sh

# 1) garantir que serviços necessários estão de pé
echo "[INFO] Subindo mqtt/mysql1/mysql2 (se ainda não estiverem)..."
docker compose up -d mqtt mysql1 mysql2

# 2) criar senha do mosquitto (pzem:2007)
echo "[INFO] Criando senha do Mosquitto..."
scripts/create-mosquitto-passwd.sh

# 3) criar usuário lamggm nos bancos
echo "[INFO] Criando usuário 'lamggm' em mysql1 e mysql2..."
scripts/create-mysql-users.sh

# 4) recriar schemas measurements (limpa e recria)
echo "[INFO] Recriando schemas measurements nos dois bancos..."
scripts/reset-mysql-schemas.sh

# 5) permissões básicas nos volumes locais (não toca no histórico do git)
echo "[INFO] Ajustando permissões em volumes locais..."
mkdir -p mosquitto/data mosquitto/log \
         mysql-data1 mysql-data2 \
         node-red-data1 node-red-data2 \
         backups rclone-config

# permitir leitura/escrita do usuário atual e do grupo (containers costumam mapear gid)
chmod -R u+rwX,g+rwX mosquitto mysql-data1 mysql-data2 node-red-data1 node-red-data2 backups rclone-config

# arquivo sensível do mosquitto
[ -f mosquitto/config/passwd ] && chmod 600 mosquitto/config/passwd

echo "[OK] Bootstrap concluído. Se algo quebrar agora é porque o universo quis."
