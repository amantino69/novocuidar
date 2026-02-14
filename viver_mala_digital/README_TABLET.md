# Guia Tablet Unico (Android)

Este guia mostra como rodar toda a operacao usando somente um tablet Android em campo.

O objetivo e:

1. Capturar anuncios BLE dos perifericos.
2. Organizar fila local.
3. Enviar dados para o servidor online.

Autoria:
- Assinatura: GUSTAVO_DEV_VP01
- Padrao de assinatura aplicado para rastreabilidade tecnica.

## Cenarios suportados no tablet

### Cenario 1: Direto para API (mais simples)

Usa `ble_passive_gateway.py` no proprio tablet.

Fluxo:

BLE -> fila local no tablet -> API online

### Cenario 2: Arquitetura completa no mesmo tablet

Usa `wifi_ble_master.py` + `wifi_ble_node.py` no mesmo tablet.

Fluxo:

BLE -> node local -> master local -> API online

Esse cenario e util para manter o mesmo padrao de operacao usado com varios nos.

## Requisitos no Android

- Android 10+ (ideal 12+)
- Bluetooth ligado
- Localizacao ligada
- Internet ativa (4G, 5G ou WiFi)
- Permissoes do app de terminal:
  - Bluetooth / Nearby devices
  - Location
- Otimizacao de bateria desativada para o app de terminal

## Preparacao do ambiente (Termux)

Instale o Termux preferencialmente pela loja F-Droid.

No Termux:

```bash
pkg update && pkg upgrade -y
pkg install python git -y
python -m pip install --upgrade pip
pip install bleak requests
```

Copie os scripts para uma pasta, por exemplo:

`~/viver_pasta`

Entre na pasta:

```bash
cd ~/viver_pasta
```

## Cenario 1: tablet enviando direto para API

### 1) Validar consulta ativa

```bash
curl -i "https://www.telecuidar.com.br/api/biometrics/active-appointment"
```

Guarde o `id` da consulta quando necessario.

### 2) Rodar o gateway direto

```bash
python3 ble_passive_gateway.py --url "https://www.telecuidar.com.br/api/biometrics/ble-reading" --max-devices 15
```

### 3) Validar logs

Procure por:

- `det` subindo (scanner ativo)
- `enq` subindo (eventos entrando na fila)
- `sent` subindo (envio concluido)
- `err` baixo ou zero

## Cenario 2: arquitetura completa no mesmo tablet

Neste cenario voce roda dois processos no mesmo tablet:

- master em `127.0.0.1:12345`
- node apontando para `127.0.0.1:12345`

### 1) Rodar o master

```bash
python3 wifi_ble_master.py --port 12345 --auth-token "token123" --appointment "SEU_GUID"
```

### 2) Rodar o node (outro terminal/sessao)

```bash
python3 wifi_ble_node.py --node-id "tablet-01" --master-host "127.0.0.1" --master-port 12345 --auth-token "token123"
```

### 3) Validar logs

No node:

- `det` sobe
- `enq` sobe quando algum MAC mapeado e reconhecido
- `sent` sobe quando o master confirma

No master:

- `recv` sobe
- `queued` sobe
- `sent` sobe quando API responde 2xx

## Teste rapido sem periferico BLE

Com master rodando, envie um payload de teste:

```bash
python3 -c "import socket,json,time; p={'token':'token123','node_id':'node-sim','timestamp':int(time.time()),'mac':'F8:8F:C8:3A:B7:92','name':'Balanca OKOK','rssi':-55,'device_type':'scale','method':'advertisement','values':{'weight':70.25},'service_data':{},'manufacturer_data':{},'service_uuids':[]}; s=socket.socket(); s.connect(('127.0.0.1',12345)); s.sendall((json.dumps(p)+'\n').encode()); print(s.recv(2048).decode().strip()); s.close()"
```

Resposta esperada:

`{"ok":true}`

## Ajuste de operacao em campo

Recomendacoes:

- manter o tablet no carregador durante atendimento
- evitar trocar entre apps durante coleta
- manter o terminal aberto em foreground
- validar internet antes da coleta
- monitorar `err` e `drop_q` nos logs

## Problemas comuns

- `Bluetooth device is turned off`
  - ative o Bluetooth e reinicie o script

- `Address already in use`
  - porta ocupada por outro processo
  - finalize processo antigo ou troque porta

- `det` sobe e `enq=0`
  - dispositivo detectado, mas sem match de MAC/regra

- `recv` sobe e `sent=0` no master
  - falha no envio para API (GUID, endpoint, internet ou retorno nao-2xx)

## Checklist final de aceite

Considere homologado quando:

- scanner ativo (`det` sobe)
- fila ativa (`enq` e `queued` sobem)
- envio confirmado (`sent` sobe)
- sem erro recorrente (`err` estabilizado)
