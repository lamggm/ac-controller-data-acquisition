#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$BASE_DIR"

# 0) garantir executáveis
chmod +x scripts/create-mosquitto-passwd.sh \
         scripts/create-mysql-users.sh \
         scripts/reset-mysql-schemas.sh \
         scripts/fix-perms.sh

# 0.1) arrumar permissões ANTES de subir qualquer coisa
echo "[INFO] Ajustando permissões de volumes..."
scripts/fix-perms.sh

# 1) subir serviços base
echo "[INFO] Subindo mqtt/mysql1/mysql2..."
docker compose up -d mqtt mysql1 mysql2

# 2) criar senha do mosquitto (pzem:2007)
echo "[INFO] Criando senha do Mosquitto (pzem:2007)..."
scripts/create-mosquitto-passwd.sh

# 3) criar usuário lamggm nos bancos
echo "[INFO] Criando usuário 'lamggm' em mysql1 e mysql2..."
scripts/create-mysql-users.sh

# 4) recriar schemas measurements
echo "[INFO] Recriando schemas measurements nos dois bancos..."
scripts/reset-mysql-schemas.sh

# 5) sanity check rápido dos bancos
echo "[INFO] Checando bancos..."
docker exec -i mysql1 mysql -uroot -p2007 -e "SHOW DATABASES; USE acdata1; SHOW TABLES;" >/dev/null
docker exec -i mysql2 mysql -uroot -p2007 -e "SHOW DATABASES; USE acdata2; SHOW TABLES;" >/dev/null
echo "[OK] MySQLs respondendo e com schema."

# 6) subir Node-RED + rclone
echo "[INFO] Subindo Node-REDs e rclone..."
docker compose up -d nodered1 nodered2 rclone

echo "[OK] Bootstrap concluído. Se algo quebrar agora, foi inveja."
