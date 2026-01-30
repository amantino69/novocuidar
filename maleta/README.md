# 🚐 TeleCuidar Maleta - Serviço BLE Itinerante

Sistema de captura automática de dispositivos médicos Bluetooth para **Maleta Itinerante de Telemedicina TeleCuidar**.

## 🎯 Conceito

A maleta viaja para comunidades remotas onde não há médicos especialistas. O técnico/enfermeiro leva a maleta e atende **múltiplos pacientes por dia**. O médico especialista fica na capital e atende via teleconsulta.

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUXO DIÁRIO                                 │
│                                                                  │
│  🏥 Capital: Médico Especialista                                 │
│       │                                                          │
│       │ Teleconsulta                                             │
│       ▼                                                          │
│  🚐 Comunidade Remota: Maleta + Técnico                          │
│       │                                                          │
│       ├── 08:00 Paciente Maria → Consulta → Sinais Vitais        │
│       ├── 08:30 Paciente João → Consulta → Sinais Vitais         │
│       ├── 09:00 Paciente Ana → Consulta → Sinais Vitais          │
│       │   ...                                                    │
│       └── 17:00 Último paciente                                  │
│                                                                  │
│  O serviço detecta AUTOMATICAMENTE cada consulta!                │
└─────────────────────────────────────────────────────────────────┘
```

## ✨ Funcionamento Automático

1. **Técnico liga a maleta** → Serviço BLE inicia automaticamente
2. **Paciente faz login** no telecuidar.com.br
3. **Paciente entra na teleconsulta** com o médico
4. **Serviço detecta** automaticamente a consulta ativa
5. **Dispositivos BLE** enviam dados para essa consulta
6. **Próximo paciente** → Nova consulta → Detecta automaticamente

**O técnico NÃO precisa configurar NADA entre pacientes!**

## 📋 Visão Geral

```
┌─────────────────────────────────────────────────────────┐
│                    MALETA TELEMEDICINA                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐│
│  │ Computador  │ │   Monitor   │ │ Equipamentos Médicos││
│  │ Windows     │ │             │ │ • Omron HEM-7156T   ││
│  │             │ │             │ │ • Balança OKOK      ││
│  │ [Serviço]   │ │ [Chrome]    │ │ • Oxímetro (futuro) ││
│  │ TeleCuidar  │ │ telecuidar  │ │ • Esteto. (futuro)  ││
│  │ BLE Service │ │ .com.br     │ │                     ││
│  └─────────────┘ └─────────────┘ └─────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## 🚀 Fluxo de Funcionamento

1. **Paciente liga a maleta** → Computador inicia
2. **Serviço BLE inicia automaticamente** → Escuta dispositivos
3. **Chrome abre telecuidar.com.br** → Paciente já logado
4. **Médico inicia a teleconsulta** → Videochamada
5. **Paciente usa os aparelhos** → Dados aparecem **instantaneamente** na tela do médico

## 📦 Instalação (Preparar Maleta)

### 1. Instalar Dependências

```powershell
cd C:\telecuidar\maleta
pip install -r requirements.txt
```

### 2. Configurar Paciente

```powershell
python setup_maleta.py --email pac_maria@telecuidar.com --senha 123
```

Para produção:
```powershell
python setup_maleta.py --email paciente@email.com --senha SENHA --producao
```

### 3. Instalar Serviço Windows

Baixe o NSSM: https://nssm.cc/download
Extraia `nssm.exe` para `C:\nssm\`

Execute como **Administrador**:
```powershell
python instalar_servico.py
```

### 4. Configurar Chrome para Abrir Automaticamente

Criar atalho na pasta Inicializar:
```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
```

Destino do atalho:
```
"C:\Program Files\Google\Chrome\Application\chrome.exe" --kiosk https://www.telecuidar.com.br
```

## 🔧 Comandos Úteis

### Gerenciar Serviço
```powershell
# Status
nssm status TeleCuidarBLE

# Parar
nssm stop TeleCuidarBLE

# Iniciar
nssm start TeleCuidarBLE

# Ver logs
Get-Content C:\telecuidar\maleta\logs\ble_service.log -Tail 50

# Remover serviço
python instalar_servico.py --uninstall
```

### Testar Manualmente
```powershell
python telecuidar_ble_service.py
```

## 📁 Estrutura de Arquivos

```
C:\telecuidar\maleta\
├── telecuidar_ble_service.py   # Serviço principal
├── setup_maleta.py             # Configura paciente
├── instalar_servico.py         # Instala serviço Windows
├── config.json                 # Configuração do paciente
├── requirements.txt            # Dependências Python
├── README.md                   # Este arquivo
└── logs/
    ├── ble_service.log         # Log do serviço
    ├── service_stdout.log      # Saída padrão
    └── service_stderr.log      # Erros
```

## 🩺 Dispositivos Suportados

| Dispositivo | MAC | Método | Status |
|-------------|-----|--------|--------|
| Balança OKOK | F8:8F:C8:3A:B7:92 | Advertisement | ✅ |
| Omron HEM-7156T | 00:5F:BF:9A:64:DF | GATT | ✅ |
| Oxímetro | - | - | 🔜 |
| Termômetro | - | - | 🔜 |
| Estetoscópio Digital | - | - | 🔜 |

## 🔄 Atualização Remota

Para atualizar a maleta remotamente:

```powershell
# Na maleta (via acesso remoto)
cd C:\telecuidar\maleta
git pull origin main
nssm restart TeleCuidarBLE
```

## ❓ Troubleshooting

### Serviço não inicia
- Verifique os logs: `C:\telecuidar\maleta\logs\`
- Verifique se o Bluetooth está ativado
- Execute manualmente para ver erros: `python telecuidar_ble_service.py`

### Dispositivo não detectado
- Verifique se o MAC está correto em `config.json`
- Verifique se o dispositivo está ligado e próximo
- O Omron precisa estar em modo de transmissão BLE

### Dados não aparecem no médico
- Verifique se há consulta ativa
- Verifique conexão com internet
- Verifique token de autenticação (pode ter expirado)

## 📞 Suporte

Em caso de problemas, verifique os logs e entre em contato com o suporte técnico.
