# Projeto — Aquisição de dados do Controlador AC

Este repositório contém a implementação do sistema de aquisição de dados para um controlador AC baseado em ESP32, sensor PZEM-004T e Raspberry Pi 5.  
O projeto inclui controle por ângulo de disparo, medição de parâmetros elétricos, comunicação via MQTT e dashboards em Node-RED.

---

## Hardware Utilizado

- **Controlador AC**: ponte completa com TRIAC/SCR + detecção de cruzamento por zero (ZCD).  
- **ESP32**: gera pulsos de disparo para TRIACs/SCRs com ISR + timer.  
- **Sensor PZEM-004T V3.0**: mede tensão, corrente, potência e fator de potência na carga (saída TTL Modbus-RTU).  
- **Raspberry Pi 5 (8 GB RAM)**: coleta dados do PZEM via USB-TTL, executa containers Docker e envia dados via MQTT.  
- **Isolação e proteção**: fusível primário, MOV, NTC, snubber RC, ZCD isolado (H11AA1 ou trafo de sinal).  
- **Carga de teste**: resistor de fio (R pura).  
- **Multímetro true-RMS**: usado para validação experimental.

---

## Estrutura do Projeto

/project-ac-controller
│── docker-compose.yml       # Containers do sistema
│── /pzem_reader             # Script Python de leitura do PZEM (Modbus-RTU)
│    └── main.py
│── /node-red-data           # Dados do Node-RED
│── /mysql-data1             # Dados MySQL (instância 1)
│── /mysql-data2             # Dados MySQL (instância 2)
│── /dashboards              # Dashboards prontos do Node-RED
│    └── ensaios-ac.json
│── /docs
│    └── instrucoes.md       # Instruções detalhadas do projeto

---

## Pipeline de Dados

1. **ESP32**  
   - Recebe sinal do cruzamento por zero (ZCD).  
   - Controla ângulo de disparo dos TRIACs/SCRs.  

2. **PZEM-004T V3.0**  
   - Mede **V RMS, I RMS, P, PF** na saída do controlador.  
   - Comunicação **TTL Modbus-RTU**.

3. **Raspberry Pi 5 (containers)**  
   - Script Python lê dados via USB-TTL.  
   - Publica dados em tópico **MQTT**.  
   - **Node-RED** exibe dashboards.  
   - **MySQL/InfluxDB** opcional para logging.  
   - **rclone** para backup no Google Drive.

---

## Containers Utilizados

- **MQTT Broker** — comunicação ESP32 ↔ Raspberry Pi.  
- **Node-RED** (até 2 instâncias) — dashboards independentes.  
- **MySQL** (até 2 instâncias) — banco de dados para logging.  
- **rclone** — sincronização com Google Drive.  
- **pzem_reader** — script em Python para leitura Modbus.  

---

## Ensaios Mínimos

- Carga resistiva pura.  
- Ângulos de disparo: `0°, 30°, 60°, 90°, 120°, 150°`.  
- Registrar: **V RMS, I RMS, P, PF**.  
- Comparar leituras do PZEM com multímetro true-RMS.  
- Validar curva **Vout(α)** com erro ≤ 5%.

---

## Como Rodar

1. Clonar este repositório:
   git clone https://github.com/<usuario>/<repo>.git
   cd <repo>

2. Subir containers:
   docker compose up -d

3. Acessar Node-RED:
   http://localhost:1880

4. Acompanhar dados via MQTT:
   mosquitto_sub -h localhost -t "ac/pzem"

---

## Status

- [x] Estrutura inicial do projeto  
- [ ] Implementação do `pzem_reader`  
- [ ] Dashboards de ensaio  
- [ ] Validação experimental  

---

## Licença

Uso acadêmico/didático. Contribuições bem-vindas.
