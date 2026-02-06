# Som de Notificação

Este diretório deve conter o arquivo de som `notification.mp3` usado para notificar médicos quando um paciente está aguardando.

## Como adicionar o arquivo de som:

### Opção 1: Baixar arquivo de som gratuito
1. Acesse: https://mixkit.co/free-sound-effects/notification/
2. Baixe um som de notificação curto (1-2 segundos)
3. Renomeie para `notification.mp3`
4. Coloque neste diretório

### Opção 2: Usar arquivo existente
Se você já tem um arquivo `.wav` ou `.ogg`, pode convertê-lo para `.mp3` usando:
- Online: https://online-audio-converter.com/
- Ou com ffmpeg: `ffmpeg -i input.wav -codec:a libmp3lame -b:a 128k notification.mp3`

## Especificações recomendadas:
- **Formato**: MP3
- **Duração**: 1-2 segundos
- **Taxa de bits**: 128 kbps
- **Volume**: Moderado (não muito alto)

## Arquivos sugeridos (gratuitos):
- https://mixkit.co/free-sound-effects/bell/ (som de sino)
- https://mixkit.co/free-sound-effects/alert/ (alerta suave)
- https://freesound.org/ (diversos sons gratuitos)

## Nota importante:
O sistema continuará funcionando sem o arquivo de som, mas o som não será reproduzido quando a notificação aparecer. Apenas o modal visual será exibido.
