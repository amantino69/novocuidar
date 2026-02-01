# Alternativas para Captura de Áudio do Eko CORE 500

## 🔍 Problema Identificado

O Eko CORE 500 provavelmente **não transmite áudio de alta qualidade via BLE GATT**.

O BLE (Bluetooth Low Energy) é usado apenas para:
- Controle do dispositivo
- Metadados
- Configurações

O áudio de alta qualidade é transmitido via:
- **Bluetooth Classic A2DP** (Audio Distribution Profile)
- **HSP/HFP** (Headset/Hands-Free Profile)

## 📋 Alternativas Viáveis

### 1. 🎧 Captura via Áudio do Windows (RECOMENDADO)

O Eko conecta como **dispositivo de áudio Bluetooth** no Windows.
Podemos capturar o áudio diretamente do input de áudio.

**Vantagens:**
- Áudio de alta qualidade (provavelmente 16-bit, 44.1kHz)
- Simples de implementar
- Funciona com qualquer estetoscópio Bluetooth

**Implementação:**
```python
import sounddevice as sd
import numpy as np
import wave

# Lista dispositivos de áudio
devices = sd.query_devices()
print(devices)

# Encontra o Eko como input
eko_device = None
for i, dev in enumerate(devices):
    if 'eko' in dev['name'].lower() or 'core' in dev['name'].lower():
        eko_device = i
        break

# Grava áudio
duration = 10  # segundos
sample_rate = 44100
recording = sd.rec(int(duration * sample_rate), 
                   samplerate=sample_rate,
                   channels=1, 
                   dtype='int16',
                   device=eko_device)
sd.wait()

# Salva WAV
with wave.open('eko_audio.wav', 'w') as f:
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(sample_rate)
    f.writeframes(recording.tobytes())
```

### 2. 📱 App Eko + Exportação

Usar o app oficial do Eko para capturar e exportar o áudio.
Depois fazer upload manual ou automático.

**Desvantagem:** Não é em tempo real.

### 3. 🔌 Captura via USB (se disponível)

Alguns modelos têm saída USB para conexão direta.

### 4. 🔊 Captura via Saída de Áudio 3.5mm

O Eko CORE 500 tem saída de fone de ouvido.
Conectar um cabo de áudio diretamente no computador.

## 🏆 Recomendação

**Usar a Opção 1 (sounddevice)** - É a mais elegante e funciona em tempo real.

### Passos para Implementar:

1. Parear o Eko como dispositivo de áudio Bluetooth no Windows
2. Instalar: `pip install sounddevice`
3. Identificar o ID do dispositivo Eko
4. Capturar áudio diretamente

## 📝 Próximos Passos

1. Verificar se o Eko está pareado como dispositivo de áudio
2. Criar script com sounddevice
3. Testar captura de áudio real
