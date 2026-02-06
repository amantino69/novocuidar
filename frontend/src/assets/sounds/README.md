# 🔊 Sistema de Sons - Instruções de Instalação

## 📁 Arquivos de Áudio Necessários

Coloque os seguintes arquivos de som na pasta `frontend/src/assets/sounds/`:

```
frontend/src/assets/sounds/
├── urgent-alert.mp3      # Som de alerta urgente (Red/Orange)
├── notification.mp3      # Som de notificação normal (Yellow/Green)
├── success.mp3           # Som de sucesso
└── warning.mp3           # Som de aviso
```

## 🎵 Recomendações de Sons

### 1. urgent-alert.mp3
- **Uso**: Demandas espontâneas críticas (vermelho/laranja)
- **Características**: 
  - Tom agudo e chamativo
  - Duração: 1-2 segundos
  - Volume: Alto (0.8)
  - Exemplo: Alarme hospitalar, beep urgente
- **Sugestões de download grátis**:
  - https://freesound.org/ - procure por "hospital alarm", "urgent beep"
  - https://mixkit.co/free-sound-effects/alarm/
  - https://pixabay.com/sound-effects/search/alarm/

### 2. notification.mp3
- **Uso**: Notificações normais (amarelo/verde)
- **Características**:
  - Tom suave e agradável
  - Duração: 0.5-1 segundo
  - Volume: Médio (0.6)
  - Exemplo: Ding, chime suave
- **Sugestões de download grátis**:
  - https://notificationsounds.com/
  - https://mixkit.co/free-sound-effects/notification/
  - https://freesound.org/ - procure por "notification", "ding"

### 3. success.mp3
- **Uso**: Ações concluídas com sucesso
- **Características**:
  - Tom positivo e curto
  - Duração: 0.5-1 segundo
  - Volume: Baixo (0.5)
  - Exemplo: "Ta-da", chime positivo
- **Sugestões de download grátis**:
  - https://mixkit.co/free-sound-effects/success/
  - https://freesound.org/ - procure por "success", "complete"

### 4. warning.mp3
- **Uso**: Avisos e alertas moderados
- **Características**:
  - Tom de atenção
  - Duração: 1 segundo
  - Volume: Médio (0.6)
  - Exemplo: Beep duplo, alerta suave
- **Sugestões de download grátis**:
  - https://mixkit.co/free-sound-effects/alert/
  - https://freesound.org/ - procure por "warning", "alert"

## 🚀 Criação Rápida de Sons Placeholder

Se você precisar de arquivos placeholder para testar, pode usar:

### Opção 1: Arquivos de Sistema (Windows)
```powershell
# Copiar sons do Windows para testes
Copy-Item "C:\Windows\Media\Windows Notify Calendar.wav" "frontend\src\assets\sounds\notification.wav"
Copy-Item "C:\Windows\Media\Windows Critical Stop.wav" "frontend\src\assets\sounds\urgent-alert.wav"
Copy-Item "C:\Windows\Media\Windows Ding.wav" "frontend\src\assets\sounds\success.wav"
Copy-Item "C:\Windows\Media\Windows Foreground.wav" "frontend\src\assets\sounds\warning.wav"

# Converter WAV para MP3 (requer ffmpeg instalado)
ffmpeg -i "frontend\src\assets\sounds\notification.wav" "frontend\src\assets\sounds\notification.mp3"
ffmpeg -i "frontend\src\assets\sounds\urgent-alert.wav" "frontend\src\assets\sounds\urgent-alert.mp3"
ffmpeg -i "frontend\src\assets\sounds\success.wav" "frontend\src\assets\sounds\success.mp3"
ffmpeg -i "frontend\src\assets\sounds\warning.wav" "frontend\src\assets\sounds\warning.mp3"
```

### Opção 2: Online Audio Generator
Use https://www.beepgen.com/ para gerar sons simples:
- **Urgent**: 1000Hz, 0.5s, Square wave
- **Notification**: 800Hz, 0.3s, Sine wave
- **Success**: 600Hz + 800Hz, 0.4s, Sine wave
- **Warning**: 900Hz, 0.5s, Triangle wave

## 📝 Checklist de Instalação

- [ ] Criar pasta `frontend/src/assets/sounds/`
- [ ] Baixar/criar arquivo `urgent-alert.mp3`
- [ ] Baixar/criar arquivo `notification.mp3`
- [ ] Baixar/criar arquivo `success.mp3`
- [ ] Baixar/criar arquivo `warning.mp3`
- [ ] Testar sons acessando console: `soundService.testSound()`
- [ ] Criar demanda espontânea urgente para testar som crítico
- [ ] Verificar controle de volume nas configurações

## 🔧 Troubleshooting

### Sons não tocam
1. Verificar se os arquivos existem na pasta correta
2. Abrir console do navegador (F12) e procurar erros
3. Verificar se o navegador permite autoplay de áudio
4. Testar em modo incógnito (sem extensões)

### Som muito alto/baixo
- Ajustar volume no código: `soundService.playSound('urgent', 0.5)` (0 a 1)
- Editar valores padrão em `sound-notification.service.ts`

### Chrome bloqueia autoplay
- O primeiro som só toca após interação do usuário
- Considerar adicionar botão "Ativar sons" no primeiro acesso

## 🎛️ Controle de Som no Frontend

O usuário pode silenciar os sons:
```typescript
// No componente do dashboard
soundService.toggleMute();  // Alterna entre ligado/desligado
soundService.isSoundMuted();  // Verifica status
```

## 📊 Uso no Sistema

### Demanda Espontânea (Recepcionista)
```typescript
// Quando criar demanda com sucesso
await soundService.playSuccess();
```

### Dashboard do Médico
```typescript
// Ao receber notificação SignalR
schedulingHub.on('NewSpontaneousDemand', async (notification) => {
  await soundService.playByUrgency(notification.urgencyLevel);
});
```

### Enfermeira (Consultório Digital)
```typescript
// Ao chamar paciente
await soundService.playNotification();
```

---

**Desenvolvido com ❤️ para o TeleCuidar POC**
