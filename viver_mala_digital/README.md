# Gateway BLE Distribuido

Este projeto implementa um fluxo de captura BLE distribuido para telemedicina.
O objetivo e permitir coleta em campo com tablet Android e envio estruturado para o backend.

Autoria:
- Assinatura: GUSTAVO_DEV_VP01
- Padrao de assinatura aplicado para rastreabilidade tecnica.

## Visao geral

Existem tres scripts principais:

- `wifi_ble_master.py`: servidor central que recebe eventos dos nos, organiza fila global e envia para a API.
- `wifi_ble_node.py`: no BLE que escaneia anuncios locais e envia dados ao mestre via TCP.
- `ble_passive_gateway.py`: coletor standalone para cenarios sem mestre/no (scanner + fila + POST direto).

Fluxo padrao:

1. Dispositivo BLE anuncia.
2. No Android captura e envia para o mestre.
3. Mestre coloca na fila, resolve `appointmentId` e envia para:
   - `/api/biometrics/ble-cache`
   - `/api/biometrics/ble-reading`

## Requisitos

- Python 3.9+
- Bibliotecas:
  - `bleak`
  - `requests`
- Bluetooth habilitado na maquina/no
- Rede entre no e mestre (WiFi/LAN)

Instalacao:

```bash
python3 -m pip install --upgrade pip
python3 -m pip install bleak requests
```

## Execucao rapida

### 1) Subir o mestre

Em producao (padrao):

```bash
python3 wifi_ble_master.py --port 12345 --auth-token "token123" --appointment "SEU_GUID"
```

Em ambiente local:

```bash
python3 wifi_ble_master.py --local --port 12345 --auth-token "token123" --appointment "SEU_GUID"
```

### 2) Subir o no

```bash
python3 wifi_ble_node.py --node-id "node-01" --master-host "IP_DO_MESTRE" --master-port 12345 --auth-token "token123"
```

Exemplo local:

```bash
python3 wifi_ble_node.py --node-id "node-01" --master-host "127.0.0.1" --master-port 12345 --auth-token "token123"
```

### 3) Simular envio sem hardware BLE

```bash
python3 -c "import socket,json,time; p={'token':'token123','node_id':'node-sim','timestamp':int(time.time()),'mac':'F8:8F:C8:3A:B7:92','name':'Balanca OKOK','rssi':-55,'device_type':'scale','method':'advertisement','values':{'weight':70.25},'service_data':{},'manufacturer_data':{},'service_uuids':[]}; s=socket.socket(); s.connect(('127.0.0.1',12345)); s.sendall((json.dumps(p)+'\n').encode()); print(s.recv(2048).decode().strip()); s.close()"
```

## Como interpretar os logs

### Mestre (`wifi_ble_master.py`)

- `recv`: quantidade recebida via TCP.
- `queued`: quantidade aceita na fila.
- `sent`: quantidade enviada para a API com sucesso.
- `err`: falhas de envio HTTP.
- `auth_fail`: token invalido.
- `invalid`: payload invalido (JSON ruim).
- `drop_q`: perda por fila cheia.

### No (`wifi_ble_node.py`)

- `det`: anuncios BLE detectados.
- `enq`: eventos aceitos para envio.
- `sent`: eventos confirmados pelo mestre.
- `err`: falhas no envio TCP para o mestre.
- `drop_dedup`: descartes por janela de deduplicacao.
- `drop_q`: descartes por fila local cheia.
- `tracked`: quantidade de MACs aceitos no ciclo.

## Dispositivos mapeados no no

O script do no trabalha com uma lista fechada de MACs:

- `F8:8F:C8:3A:B7:92` -> `scale`
- `00:5F:BF:9A:64:DF` -> `blood_pressure`
- `DC:23:4E:DA:E9:DD` -> `thermometer`
- `88:D2:11:C8:20:31` -> `stethoscope`

Se o MAC nao estiver nessa lista, ele conta em `det`, mas nao entra em `enq`.

## Android em campo

Para usar o tablet como no:

1. Instalar Python no Android (Termux ou equivalente).
2. Instalar dependencias (`bleak`, `requests`).
3. Garantir permissoes de Bluetooth e localizacao.
4. Desativar otimizacao de bateria para o app/processo.
5. Rodar `wifi_ble_node.py` apontando para o IP do mestre.

## Problemas comuns

- `Address already in use` no mestre:
  - porta ocupada por outro processo.
  - solucao: encerrar processo antigo ou trocar porta.

- `Bluetooth device is turned off`:
  - Bluetooth desativado no host/no.

- `det` sobe e `enq=0`:
  - MAC nao mapeado ou sem payload valido para regra atual.

- `recv` sobe e `sent=0` no mestre:
  - problema de API (`appointmentId`, endpoint, conectividade ou resposta nao-2xx).

## Boas praticas para operacao

- Sempre validar `active-appointment` antes de iniciar coleta.
- Manter `auth-token` sincronizado entre no e mestre.
- Monitorar `err` e `drop_q` durante janela de atendimento.
- Em campo, priorizar conexao de dados estavel para evitar backlog.
