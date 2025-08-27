# Projeto — Aquisição de Dados do Controlador AC

Implementação de aquisição de dados para um controlador AC com **ESP32**, **PZEM-004T v3.0** e **Raspberry Pi 5**.  
Arquitetura 100% em **Docker Compose**: **MQTT (Mosquitto)**, **Node-RED** (2 instâncias), **MySQL** (2 instâncias), **rclone** (backup para Google Drive) e **pzem_reader** (coleta Modbus-RTU).

---

## Hardware

- Controlador AC: ponte completa com TRIAC/SCR + ZCD (H11AA1 ou trafo de sinal)
- ESP32: ISR + timer com ângulo de disparo por fase
- PZEM-004T v3.0: V_RMS, I_RMS, P, PF (TTL Modbus-RTU 9600 8N1)
- Raspberry Pi 5 (8 GB): roda os containers
- Proteções: fusível primário, MOV, NTC, snubber RC (47 nF X2 + 100 Ω)
- Carga de ensaio: resistor de fio (R pura)
- Multímetro true-RMS para validação

---

## Estrutura

```
ac-controller-data-acquisition/
│── docker-compose.yml
│── .env
│── mosquitto/
│   ├── config/mosquitto.conf
│   ├── data/
│   └── log/
│── node-red-data1/
│── node-red-data2/
│── mysql-data1/
│── mysql-data2/
│── mysql-init1/001-schema.sql
│── mysql-init2/001-schema.sql
│── pzem_reader/
│   ├── Dockerfile
│   └── main.py
│── rclone-config/
│── backups/
│── scripts/
│   ├── bootstrap.sh
│   ├── fix-perms.sh
│   ├── create-mosquitto-passwd.sh
│   ├── create-mysql-users.sh
│   └── reset-mysql-schemas.sh
│── dashboards/
│   └── ensaios-ac.json
└── docs/instrucoes.md
```

---

## Pipeline de Dados

1. **ESP32** detecta ZCD e define o ângulo α (controle por fase).
2. **PZEM-004T** mede V, I, P e PF na saída do controlador.
3. **pzem_reader** (Python) lê via Modbus-RTU e publica em **MQTT**.
4. **Node-RED** consome MQTT, exibe dashboards e grava em **MySQL**.
5. **rclone** sincroniza a pasta `backups/` com o **Google Drive**.

---

## Serviços e Portas

| Serviço     | Porta Host | Descrição                          |
|-------------|------------|------------------------------------|
| mqtt        | 1883/9001  | Mosquitto (TCP/WebSockets)         |
| nodered1    | 1880       | Node-RED instância 1               |
| nodered2    | 1881       | Node-RED instância 2               |
| mysql1      | 3307       | MySQL instância 1                  |
| mysql2      | 3308       | MySQL instância 2                  |
| rclone (rc) | 5572       | API Web do rclone (sem GUI web)    |

---

## Como Rodar (Raspberry Pi)

> Pré-requisitos: Docker + Docker Compose instalados. Não instale nada fora de containers.

1) **Clonar e entrar no diretório**
```bash
git clone https://github.com/lamggm/ac-controller-data-acquisition.git
cd ac-controller-data-acquisition
```

2) **Permitir execução dos scripts**
```bash
chmod +x scripts/*.sh
```

3) **Bootstrap completo (sobe broker e bancos, cria usuários, schemas e ajusta permissões)**
```bash
./scripts/bootstrap.sh
```

4) **Subir todos os serviços principais**
```bash
docker compose up -d mqtt mysql1 mysql2 nodered1 nodered2 rclone
docker ps
```

5) **Acessos**
- Node-RED 1: `http://<IP_DO_RP5>:1880`
- Node-RED 2: `http://<IP_DO_RP5>:1881`
- MQTT: host `<IP_DO_RP5>` porta `1883`
- MySQL 1: host `<IP_DO_RP5>` porta `3307`
- MySQL 2: host `<IP_DO_RP5>` porta `3308`

6) **Credenciais padrão**
- **MQTT**: user `pzem` / senha `2007`
- **MySQL**: user `lamggm` / senha `2007` (dbs `acdata1` e `acdata2`)

---

## Configuração do rclone (Google Drive)

O container `rclone` expõe a API RC na porta `5572`. Para configurar seu Google Drive:

1) **Entrar no container e abrir o configurador**
```bash
docker exec -it rclone rclone config
```

2) **Criar um remote do tipo `drive`**
- Nome sugerido: `bkp-dados-ac-controler`
- `client_id` e `client_secret`: deixar em branco ou usar os seus
- `scope`: `drive`
- `Edit advanced config?` → `n`
- `Use web browser to automatically authenticate?` → `n`
- Siga a instrução exibida (`rclone authorize "drive" "<token>"`) em um PC com navegador e cole o `config_token` de volta no terminal do Pi.

3) **Teste**
```bash
docker exec -it rclone rclone listremotes
docker exec -it rclone rclone mkdir bkp-dados-ac-controler:ac-controller-backups
docker exec -it rclone rclone ls bkp-dados-ac-controler:
```

4) **Upload manual da pasta de backup**
```bash
# crie um arquivo de teste
echo "backup de teste $(date -Iseconds)" > backups/hello.txt

# envie tudo de /backups para a pasta do Drive
docker exec -it rclone rclone copy /data bkp-dados-ac-controler:ac-controller-backups --progress
```

> Obs.: o `rclone` aqui está em modo “servidor” (rcd). A sincronização periódica automática não está habilitada por padrão. Para backup automático, use um flow no Node-RED chamando `rclone rc` ou crie um serviço sidecar com `rclone sync` em intervalos definidos.

---

## Node-RED: fluxo mínimo (MQTT → MySQL)

1) Na paleta, instale **`node-red-node-mysql`**.
2) Crie o fluxo:
- **mqtt in**: tópico `ac/pzem/metrics`, auth `pzem/2007`
- **function** (prepara `msg.params`):
```js
// assume payload = { V_RMS, I_RMS, P, PF, ts }
msg.params = {
  V_RMS: msg.payload.V_RMS,
  I_RMS: msg.payload.I_RMS,
  P:     msg.payload.P,
  PF:    msg.payload.PF
};
return msg;
```
- **mysql** (conexão mysql1 → `acdata1`) com a query:
```sql
INSERT INTO measurements (v_rms, i_rms, p_w, pf)
VALUES (:V_RMS, :I_RMS, :P, :PF);
```

---

## Ensaios Mínimos

- Carga resistiva pura.
- Ângulos: `0°, 30°, 60°, 90°, 120°, 150°`.
- Registrar: V_RMS, I_RMS, P, PF (PZEM) e comparar com multímetro true-RMS.
- Validar Vout(α) com erro ≤ 5%.

---

## Status Atual

- [x] MQTT, MySQL (x2), Node-RED (x2) e rclone rodando
- [x] Scripts: bootstrap, fix-perms, criação de usuários e schemas
- [x] Credenciais definidas (MQTT `pzem/2007`, MySQL `lamggm/2007`)
- [x] Upload manual de `backups/` para Google Drive via rclone
- [ ] Automação de backup periódico (flow/sidecar)
- [ ] Integração final do `pzem_reader` no ensaio
- [ ] Dashboards definitivos e validação experimental

---

## Licença

Uso acadêmico/didático. Contribuições bem-vindas.
