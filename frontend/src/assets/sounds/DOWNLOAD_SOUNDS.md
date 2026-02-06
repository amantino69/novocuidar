# 🎵 Sons Gratuitos Recomendados - Links Diretos

## Download Rápido (Opção 1 - Mixkit)

### 1. urgent-alert.mp3
**Link:** https://mixkit.co/free-sound-effects/alarm/
- **Recomendado**: "Hospital Emergency Alarm" ou "Medical Alert Beep"
- Buscar por: "medical", "emergency", "alarm"
- Download gratuito sem cadastro

### 2. notification.mp3
**Link:** https://mixkit.co/free-sound-effects/notification/
- **Recomendado**: "Interface Message Notification" (#2354)
- Som suave de notificação
- Download direto em MP3

### 3. success.mp3
**Link:** https://mixkit.co/free-sound-effects/success/
- **Recomendado**: "Quick Positive Notification" (#2356)
- Som de sucesso curto e agradável
- Formato MP3 pronto para uso

### 4. warning.mp3
**Link:** https://mixkit.co/free-sound-effects/alert/
- **Recomendado**: "Alert Error" ou "System Alert Warning"
- Som de atenção moderado
- Download gratuito

---

## Download Rápido (Opção 2 - Freesound.org)

### Cadastro Necessário (Gratuito)
1. Criar conta em https://freesound.org/
2. Buscar e baixar os sons abaixo:

### Sons Recomendados:

#### urgent-alert.mp3
- **ID**: 387 - "Hospital Alert.wav" by deleted_user_877451
- **Ou**: 156031 - "Medical Alert" by andersmmg
- **Buscar**: https://freesound.org/search/?q=hospital+alarm&f=duration%3A%5B0+TO+2%5D

#### notification.mp3
- **ID**: 322903 - "Notification 3" by FoolBoyMedia
- **Ou**: 397355 - "notification_simple" by plasterbrain
- **Buscar**: https://freesound.org/search/?q=notification+soft&f=duration%3A%5B0+TO+1%5D

#### success.mp3
- **ID**: 341695 - "Success" by unadamlar
- **Ou**: 316920 - "Success" by Leszek_Szary
- **Buscar**: https://freesound.org/search/?q=success+chime

#### warning.mp3
- **ID**: 278142 - "Two Beep" by TiesWijnen
- **Ou**: 320181 - "UI Warning" by tec_studio
- **Buscar**: https://freesound.org/search/?q=warning+beep

---

## Opção 3 - Sons do Windows (Rápido para Teste)

```powershell
# Execute no PowerShell para copiar sons do Windows
mkdir "C:\telecuidar\frontend\src\assets\sounds" -Force

# Copiar sons do sistema
Copy-Item "C:\Windows\Media\Windows Notify System Generic.wav" "C:\telecuidar\frontend\src\assets\sounds\notification.wav"
Copy-Item "C:\Windows\Media\Windows Critical Stop.wav" "C:\telecuidar\frontend\src\assets\sounds\urgent-alert.wav"
Copy-Item "C:\Windows\Media\Windows Ding.wav" "C:\telecuidar\frontend\src\assets\sounds\success.wav"
Copy-Item "C:\Windows\Media\Windows Foreground.wav" "C:\telecuidar\frontend\src\assets\sounds\warning.wav"
```

**Nota**: Se quiser converter para MP3, instale ffmpeg:
```powershell
# Instalar ffmpeg via chocolatey
choco install ffmpeg -y

# Converter para MP3
cd "C:\telecuidar\frontend\src\assets\sounds"
ffmpeg -i notification.wav -b:a 128k notification.mp3
ffmpeg -i urgent-alert.wav -b:a 128k urgent-alert.mp3
ffmpeg -i success.wav -b:a 128k success.mp3
ffmpeg -i warning.wav -b:a 128k warning.mp3

# Remover arquivos WAV
Remove-Item *.wav
```

---

## Opção 4 - Gerar Sons Online (Simples)

### Usando Beepgen (https://www.beepgen.com/)

1. **urgent-alert.mp3**
   - Frequência: 1200 Hz
   - Duração: 0.5 segundos
   - Forma de onda: Square
   - Repetir: 2x com 0.1s de pausa
   - Download MP3

2. **notification.mp3**
   - Frequência: 800 Hz
   - Duração: 0.3 segundos
   - Forma de onda: Sine
   - Download MP3

3. **success.mp3**
   - Frequência inicial: 600 Hz → 800 Hz
   - Duração: 0.4 segundos
   - Forma de onda: Sine
   - Download MP3

4. **warning.mp3**
   - Frequência: 900 Hz
   - Duração: 0.5 segundos
   - Forma de onda: Triangle
   - Download MP3

---

## Script Automático de Download (PowerShell)

Salve como `download-sounds.ps1` e execute:

```powershell
# Script para baixar sons de exemplo do Mixkit
$soundsDir = "C:\telecuidar\frontend\src\assets\sounds"
New-Item -ItemType Directory -Force -Path $soundsDir | Out-Null

Write-Host "Baixando sons de notificação..." -ForegroundColor Cyan

# URLs de exemplo (substitua pelos links reais após visitar o site)
$sounds = @{
    "urgent-alert.mp3" = "https://assets.mixkit.co/sfx/preview/mixkit-alarm-digital-clock-beep-989.mp3"
    "notification.mp3" = "https://assets.mixkit.co/sfx/preview/mixkit-message-pop-alert-2354.mp3"
    "success.mp3" = "https://assets.mixkit.co/sfx/preview/mixkit-quick-positive-video-game-notification-interface-265.mp3"
    "warning.mp3" = "https://assets.mixkit.co/sfx/preview/mixkit-system-beep-buzzer-fail-2964.mp3"
}

foreach ($sound in $sounds.GetEnumerator()) {
    $outputPath = Join-Path $soundsDir $sound.Key
    Write-Host "Baixando $($sound.Key)..." -ForegroundColor Yellow
    
    try {
        Invoke-WebRequest -Uri $sound.Value -OutFile $outputPath -UseBasicParsing
        Write-Host "✓ $($sound.Key) baixado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erro ao baixar $($sound.Key): $_" -ForegroundColor Red
    }
}

Write-Host "`nDownloads concluídos! Verifique a pasta:" -ForegroundColor Cyan
Write-Host $soundsDir -ForegroundColor White
```

Execute:
```powershell
cd C:\telecuidar
.\download-sounds.ps1
```

---

## Verificação Final

Após baixar os sons, verifique:

```powershell
# Listar arquivos de som
Get-ChildItem "C:\telecuidar\frontend\src\assets\sounds" | Format-Table Name, Length, LastWriteTime

# Deve mostrar:
# urgent-alert.mp3
# notification.mp3
# success.mp3
# warning.mp3
```

## Teste no Frontend

```typescript
// Abrir console do navegador (F12) e executar:
const soundService = window.injector.get('SoundNotificationService');
await soundService.testSound();

// Testar cada som individualmente:
await soundService.playUrgentAlert();
await soundService.playNotification();
await soundService.playSuccess();
await soundService.playWarning();
```

---

**Dica**: Recomendo começar com **Opção 1 (Mixkit)** por ser o mais rápido e sem cadastro!
