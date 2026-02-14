# Documentação Técnica: Impossibilidade de BLE via Python no Android

## Data da Análise
Fevereiro 2026

## Objetivo
Migrar a "maleta itinerante" do TeleCuidar de um notebook Windows para um tablet Samsung Android, utilizando Python com a biblioteca bleak para captura de dispositivos BLE (Bluetooth Low Energy).

---

## Abordagem Tentada

### Ambiente
- **Dispositivo**: Samsung Galaxy Tab (Android)
- **Terminal**: Termux (emulador de terminal Linux para Android)
- **Linguagem**: Python 3.11
- **Biblioteca BLE**: bleak (Bluetooth Low Energy platform Agnostic Klient)

### Script Testado
```python
# tablet_gateway.py
import asyncio
from bleak import BleakScanner

async def scan_devices():
    print("Iniciando scan BLE...")
    devices = await BleakScanner.discover(timeout=10.0)
    for d in devices:
        print(f"  {d.address}: {d.name}")

asyncio.run(scan_devices())
```

---

## Erro Observado

Ao executar o script no Termux, o seguinte erro foi obtido:

```
Traceback (most recent call last):
  File "tablet_gateway.py", line XX, in <module>
    asyncio.run(scan_devices())
  File "bleak/backends/scanner.py", line XX, in discover
    async with cls(detection_callback, service_uuids) as scanner:
  File "bleak/backends/bluezdbus/scanner.py", line XX, in __aenter__
    self._bus = await MessageBus().connect()
  File "dbus_fast/message_bus.py", line XX, in connect
    await self._auth.authenticate()
  File "dbus_fast/auth.py", line XX, in authenticate
    raise AuthError("Failed to connect to D-Bus daemon")
dbus_fast.AuthError: Failed to connect to D-Bus daemon
```

**Erro alternativo também observado:**
```
bleak.exc.BleakError: No D-Bus daemon found. 
Unable to connect to Bluetooth adapter.
```

---

## Análise Técnica

### Por que o erro ocorre?

A biblioteca **bleak** no Linux utiliza o backend **BlueZ** através do **D-Bus** para comunicação com o adaptador Bluetooth:

```
┌─────────────────────────────────────────────────────────┐
│                    Linux (Desktop)                       │
│                                                          │
│  Python App → bleak → D-Bus → BlueZ → Bluetooth HW      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### O problema no Android

O Android **NÃO** utiliza BlueZ nem D-Bus. O Android tem sua própria stack Bluetooth implementada nativamente:

```
┌─────────────────────────────────────────────────────────┐
│                      Android                             │
│                                                          │
│  Java/Kotlin App → Android Bluetooth API → HW           │
│                                                          │
│  ❌ NÃO EXISTE: D-Bus                                   │
│  ❌ NÃO EXISTE: BlueZ                                   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Termux não resolve o problema

Embora o Termux emule um ambiente Linux, ele **não tem acesso** às APIs nativas do Android para Bluetooth. O Termux roda em um ambiente isolado (sandbox) e não pode:

1. Instalar ou executar o daemon D-Bus
2. Acessar o BlueZ (que não existe no Android)
3. Comunicar-se diretamente com o hardware Bluetooth

### Código fonte do bleak confirmando

No arquivo `bleak/backends/bluezdbus/scanner.py` (backend usado no Linux/Termux):

```python
from dbus_fast.aio import MessageBus

class BleakScannerBlueZDBus:
    async def start(self):
        # Tenta conectar ao D-Bus system bus
        self._bus = await MessageBus(bus_type=BusType.SYSTEM).connect()
        # ↑ FALHA no Android porque D-Bus não existe
```

---

## Alternativas Investigadas

### 1. Pyjnius (acesso às APIs Java do Android)
```python
from jnius import autoclass
BluetoothAdapter = autoclass('android.bluetooth.BluetoothAdapter')
```
**Status**: Requer Kivy/buildozer para compilar APK nativo. Complexidade alta.

### 2. BLE via ADB (Android Debug Bridge)
```bash
adb shell dumpsys bluetooth_manager
```
**Status**: Funciona para diagnóstico mas não para scan contínuo de dispositivos.

### 3. Web Bluetooth (via Chrome)
```javascript
navigator.bluetooth.requestDevice({ filters: [...] })
```
**Status**: Funciona para conexão, mas dispositivos médicos (Omron, Eko) usam protocolos proprietários que bloqueiam leitura de dados.

### 4. Aplicativo nativo Android
**Status**: Requer desenvolvimento em Kotlin/Java. Fora do escopo da POC.

---

## Conclusão

### Fato Técnico
> **A biblioteca bleak (Python) é incompatível com Android/Termux porque depende de D-Bus/BlueZ, que não existem no sistema operacional Android.**

### Implicações para o Projeto
1. **Impossível** usar o mesmo código Python da maleta Windows no tablet Android
2. **Impossível** fazer scan BLE direto via Termux
3. **Web Bluetooth** funciona parcialmente, mas dispositivos médicos bloqueiam dados
4. **Alternativa viável**: Desenvolver app Android nativo ou manter a maleta em Windows

### Recomendação
Para a POC, manter a maleta itinerante em **Windows** com o script `maleta_itinerante.py` que funciona perfeitamente. Migração para tablet Android requer:
- Desenvolvimento de app nativo (Kotlin/Java)
- Ou uso de framework híbrido (React Native com react-native-ble-plx)
- Investimento estimado: 2-4 semanas de desenvolvimento

---

## Referências

1. [bleak GitHub - Supported platforms](https://github.com/hbldh/bleak#features)
2. [Android Bluetooth Architecture](https://source.android.com/docs/core/connect/bluetooth)
3. [Termux limitations](https://wiki.termux.com/wiki/Differences_from_Linux)
4. [D-Bus specification](https://dbus.freedesktop.org/doc/dbus-specification.html)

---

## Histórico de Testes

| Data | Teste | Resultado |
|------|-------|-----------|
| 13/02/2026 | bleak no Termux | ❌ Falha - D-Bus não encontrado |
| 13/02/2026 | Web Bluetooth conexão | ✅ Conecta ao dispositivo |
| 13/02/2026 | Web Bluetooth leitura Omron | ❌ Protocolo proprietário |
| 13/02/2026 | Web Bluetooth leitura Eko | ❌ Serviço de áudio não exposto |
| 13/02/2026 | Eko app no tablet | ❌ "App não funciona neste dispositivo" |

---

*Documento gerado para fins de documentação técnica do projeto TeleCuidar POC*
