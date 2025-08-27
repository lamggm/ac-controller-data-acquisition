#!/bin/bash
set -euo pipefail

ROOT_PASS="2007"
TABLE_SQL='
DROP TABLE IF EXISTS measurements;
CREATE TABLE IF NOT EXISTS measurements (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  v_rms DOUBLE NOT NULL,
  i_rms DOUBLE NOT NULL,
  p_w DOUBLE NOT NULL,
  pf DOUBLE NOT NULL,
  PRIMARY KEY (id),
  INDEX (ts)
);
'

echo "[INFO] Recriando schemas 'measurements' em mysql1/acdata1 e mysql2/acdata2"

docker exec -i mysql1 mysql -uroot -p"$ROOT_PASS" acdata1 <<< "$TABLE_SQL"
echo "[OK] mysql1/acdata1 pronto"

docker exec -i mysql2 mysql -uroot -p"$ROOT_PASS" acdata2 <<< "$TABLE_SQL"
echo "[OK] mysql2/acdata2 pronto"
