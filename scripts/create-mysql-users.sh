#!/bin/bash
set -euo pipefail

# credenciais root (iguais nos dois .env)
ROOT_PASS="2007"
DB1="acdata1"
DB2="acdata2"

echo "[INFO] Criando usuário 'lamggm' nos dois bancos..."

# Função auxiliar
create_user() {
  local container=$1
  local db=$2
  echo "[INFO] -> Container: $container, DB: $db"
  docker exec -i "$container" mysql -uroot -p"$ROOT_PASS" <<SQL
CREATE USER IF NOT EXISTS 'lamggm'@'%' IDENTIFIED BY '2007';
GRANT ALL PRIVILEGES ON \`$db\`.* TO 'lamggm'@'%';
FLUSH PRIVILEGES;
SQL
}

create_user mysql1 "$DB1"
create_user mysql2 "$DB2"

echo "[OK] Usuário 'lamggm' criado com senha '2007' em mysql1 e mysql2"
