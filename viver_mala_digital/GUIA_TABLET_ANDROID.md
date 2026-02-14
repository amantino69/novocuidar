# TeleCuidar - Configuração do Tablet Android

Este guia explica como configurar um tablet Samsung Android para funcionar como maleta de telemedicina.

## Visão Geral da Arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                    TABLET ANDROID (MALETA)                        │
│                                                                   │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────────────┐ │
│  │   Chrome    │     │   Termux    │     │  Equipamentos BLE   │ │
│  │ (Operador)  │     │ (Gateway)   │     │  • Balança OKOK     │ │
│  │             │     │             │◄────│  • Omron HEM-7156T  │ │
│  │ telecuidar  │     │ tablet_     │     │  • Termômetro MOBI  │ │
│  │ .com.br     │     │ gateway.py  │     └─────────────────────┘ │
│  └──────┬──────┘     └──────┬──────┘                              │
│         │                   │                                     │
│         │    Internet (4G/WiFi)                                   │
└─────────┼───────────────────┼─────────────────────────────────────┘
          │                   │
          ▼                   ▼
┌──────────────────────────────────────────────────────────────────┐
│                    SERVIDOR TELECUIDAR (VPS)                      │
│         https://www.telecuidar.com.br/api/biometrics              │
│                                                                   │
│  Portal Web ◄──── SignalR ────► Tela do Médico                   │
└──────────────────────────────────────────────────────────────────┘
```

## Passo 1: Instalar F-Droid

**IMPORTANTE**: NÃO instale Termux pela Play Store (versão abandonada).

1. No tablet, abra o Chrome
2. Acesse: https://f-droid.org
3. Clique em "Download F-Droid"
4. Abra o arquivo APK baixado
5. Se aparecer aviso de segurança:
   - Vá em **Configurações > Segurança**
   - Ative **"Fontes desconhecidas"** ou **"Instalar apps desconhecidos"**
   - Volte e conclua a instalação

## Passo 2: Instalar Termux pelo F-Droid

1. Abra o **F-Droid**
2. Aguarde a atualização dos repositórios (pode levar 1-2 minutos)
3. Toque na lupa (busca) e digite: **termux**
4. Selecione **"Termux"** (sem sufixos)
5. Toque em **"Instalar"**
6. Após instalar, **NÃO abra ainda**

## Passo 3: Instalar Termux:API (opcional, mas recomendado)

1. Ainda no F-Droid, busque: **termux api**
2. Instale o **"Termux:API"**
3. Este pacote permite acesso a recursos do Android (câmera, sensores, etc.)

## Passo 4: Configurar Permissões do Termux

1. Vá em **Configurações do Android > Aplicativos > Termux**
2. Toque em **"Permissões"**
3. Ative **TODAS** as permissões:
   - ✅ Localização (obrigatório para BLE)
   - ✅ Arquivos/Armazenamento
   - ✅ Bluetooth (se disponível)
   - ✅ Dispositivos próximos / Nearby devices
4. Em **"Bateria"**, selecione **"Sem restrições"** ou **"Não otimizar"**

## Passo 5: Configurar Termux

Abra o **Termux** e execute os comandos abaixo (copie um por um):

```bash
# Atualizar pacotes
pkg update && pkg upgrade -y

# Instalar Python e Git
pkg install python git -y

# Atualizar pip
python -m pip install --upgrade pip

# Instalar dependências
pip install bleak aiohttp

# Criar pasta do projeto
mkdir -p ~/telecuidar
cd ~/telecuidar
```

### Se der erro "mirrors not accessible":

```bash
# Trocar para mirror funcional
termux-change-repo
# Selecione: "Main repository" → "Grimler" ou "BFSU"

# Depois tente novamente
pkg update
pkg install python git -y
```

## Passo 6: Baixar o Script

No Termux:

```bash
cd ~/telecuidar

# Opção A: Baixar direto do servidor
curl -O https://raw.githubusercontent.com/amantino69/novocuidar/main/viver_mala_digital/tablet_gateway.py

# Opção B: Se o curl não funcionar, copie o arquivo manualmente
# (veja seção "Alternativa: Copiar Manualmente" abaixo)
```

## Passo 7: Testar a Instalação

```bash
cd ~/telecuidar

# Teste básico (verifica se Python funciona)
python --version

# Teste de conexão com servidor
python tablet_gateway.py --test
```

Se aparecer **"Consulta ativa: ..."**, está funcionando!

## Passo 8: Criar Atalho na Área de Trabalho

No Termux:

```bash
# Criar script de inicialização
cat > ~/telecuidar/start.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/telecuidar
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           TELECUIDAR - MALETA TELEMEDICINA                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
python tablet_gateway.py
EOF

chmod +x ~/telecuidar/start.sh

# Criar atalho no home do Termux
echo 'cd ~/telecuidar && ./start.sh' >> ~/.bashrc
```

Agora, toda vez que abrir Termux, o gateway inicia automaticamente.

## Usando no Dia a Dia

### Fluxo de Operação:

1. **Operador** conecta tablet na internet (WiFi ou 4G)
2. **Operador** abre Chrome e faz login em telecuidar.com.br
3. **Operador** entra na sala de teleconsulta com o paciente
4. **Operador** abre Termux (gateway inicia automaticamente)
5. **Dispositivos** BLE são detectados e dados enviados ao médico

### Comandos Úteis no Termux:

```bash
# Iniciar gateway (produção)
python ~/telecuidar/tablet_gateway.py

# Iniciar gateway (homologação local)
python ~/telecuidar/tablet_gateway.py --local

# Testar conexão
python ~/telecuidar/tablet_gateway.py --test

# Ver status do Bluetooth
termux-bluetooth-scan  # (requer Termux:API)
```

## Dispositivos Suportados

| Dispositivo | MAC | Tipo | Método |
|------------|-----|------|--------|
| Balança OKOK | F8:8F:C8:3A:B7:92 | scale | Advertisement |
| Omron HEM-7156T | 00:5F:BF:9A:64:DF | blood_pressure | GATT |
| Termômetro MOBI | DC:23:4E:DA:E9:DD | thermometer | GATT |

### Adicionar Novo Dispositivo:

Se você tem um dispositivo com MAC diferente, edite o arquivo `tablet_gateway.py`:

```python
DEVICES = {
    "XX:XX:XX:XX:XX:XX": {  # Substitua pelo MAC real
        "type": "scale",       # ou blood_pressure, thermometer
        "name": "Nome do Dispositivo",
        "method": "advertisement"  # ou gatt
    },
    # ... demais dispositivos
}
```

## Troubleshooting

### Erro: "mirrors not accessible"
- Solução: Use Termux do F-Droid, não da Play Store
- Execute: `termux-change-repo` e escolha outro mirror

### Erro: "Bluetooth device is turned off"
- Ative o Bluetooth nas configurações do Android
- Verifique permissões do Termux (Bluetooth + Localização)

### Erro: "Permission denied"
- Vá em Configurações > Aplicativos > Termux > Permissões
- Ative TODAS as permissões
- Reinicie o Termux

### Nenhum dispositivo detectado
1. Verifique se o Bluetooth está ligado
2. Verifique se a Localização está ligada
3. Confirme o MAC do dispositivo com `hcitool lescan` ou app nRF Connect

### Gateway não envia dados
1. Verifique se há consulta ativa no navegador
2. Teste com: `python tablet_gateway.py --test`
3. Verifique conexão com internet

## Alternativa: Copiar Script Manualmente

Se não conseguir baixar via curl:

1. No PC, abra o arquivo `viver_mala_digital/tablet_gateway.py`
2. Copie todo o conteúdo
3. No tablet, abra o Termux
4. Execute:
   ```bash
   mkdir -p ~/telecuidar
   nano ~/telecuidar/tablet_gateway.py
   ```
5. Cole o conteúdo (toque longo > Colar)
6. Salve: Ctrl+O, Enter, Ctrl+X

## Alternativa: Usar Pydroid3 (Se Termux Não Funcionar)

Se Termux definitivamente não funcionar, use o **Pydroid 3**:

1. Instale **Pydroid 3** da Play Store
2. No Pydroid, vá em **Menu > Pip** e instale:
   - `bleak`
   - `aiohttp`
3. Copie o script `tablet_gateway.py` para o tablet
4. Abra o arquivo no Pydroid e execute

**Nota**: Pydroid pode ter limitações com BLE em alguns dispositivos.

## Checklist de Configuração

- [ ] F-Droid instalado
- [ ] Termux instalado pelo F-Droid
- [ ] Permissões do Termux configuradas
- [ ] Bluetooth ligado
- [ ] Localização ligada
- [ ] Python instalado (`python --version`)
- [ ] bleak instalado (`pip show bleak`)
- [ ] aiohttp instalado (`pip show aiohttp`)
- [ ] Script tablet_gateway.py baixado
- [ ] Teste bem-sucedido (`python tablet_gateway.py --test`)
- [ ] Bateria configurada para não otimizar Termux

## Contato

Em caso de dúvidas:
- Documentação: https://github.com/amantino69/novocuidar
- Sistema: https://www.telecuidar.com.br
