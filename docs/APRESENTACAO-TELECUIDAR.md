# 🏥 TeleCuidar - Apresentação para Stakeholders
## Roteiro de Demonstração do Sistema

**Data:** 12 de Fevereiro de 2026  
**Audiência:** Sócios, Investidores e Médicos  
**Duração Estimada:** 45-60 minutos

---

# 📋 ROTEIRO DA APRESENTAÇÃO

---

## PARTE 1: INTRODUÇÃO (5 minutos)

### Slide/Momento de Abertura

**O que falar:**
> "Bem-vindos à apresentação do TeleCuidar, uma plataforma completa de telemedicina desenvolvida para atender comunidades remotas e descentralizar o acesso à saúde especializada."

> "O TeleCuidar resolve um problema real: milhões de brasileiros em áreas remotas não têm acesso a médicos especialistas. Nossa solução leva o especialista até o paciente através da tecnologia."

### Conceito Central

**O que falar:**
> "Imagine uma comunidade ribeirinha no interior do Amazonas. Hoje, se um paciente precisa de um psiquiatra ou cardiologista, ele precisa viajar horas ou dias até a capital. Com o TeleCuidar, montamos um Consultório Digital na própria comunidade, onde um técnico de enfermagem auxilia o paciente enquanto o médico especialista atende remotamente."

---

## PARTE 2: ARQUITETURA DA SOLUÇÃO (5 minutos)

### Componentes do Sistema

**O que falar:**
> "O TeleCuidar é composto por três pilares:"

1. **Plataforma Web** - Acessível em qualquer navegador
2. **Maleta Itinerante** - Kit portátil com dispositivos médicos conectados
3. **Integração com Dispositivos** - Captura automática de sinais vitais via Bluetooth

**Demonstrar no sistema:**
- Acessar https://www.telecuidar.com.br
- Mostrar a tela de login
- Explicar que funciona em qualquer dispositivo com internet

---

## PARTE 3: PERFIS DE USUÁRIO (10 minutos)

### 3.1 Administrador

**O que falar:**
> "O administrador tem controle total do sistema. Ele gerencia usuários, especialidades, unidades de saúde e monitora tudo através de relatórios e logs de auditoria."

**Demonstrar no sistema:**
- Login com: `adm_ca@telecuidar.com` / senha: `123`
- Mostrar o painel administrativo
- Navegar por:
  - **Usuários** - Cadastro de médicos, enfermeiros, pacientes
  - **Especialidades** - Configuração de especialidades médicas
  - **Unidades de Saúde** - Cadastro de estabelecimentos
  - **Agendas** - Configuração de horários por profissional
  - **Relatórios** - Métricas de atendimento
  - **Logs de Auditoria** - Rastreabilidade total de ações

---

### 3.2 Médico/Profissional de Saúde

**O que falar:**
> "O médico tem uma visão focada no atendimento. Ele visualiza sua agenda, acessa as teleconsultas e tem todas as ferramentas clínicas necessárias."

**Demonstrar no sistema:**
- Login com: `med_gt@telecuidar.com` / senha: `123` (Clínica Geral)
- Ou: `med_aj@telecuidar.com` / senha: `123` (Psiquiatria)
- Mostrar:
  - **Painel do Profissional** - Visão geral do dia
  - **Minha Agenda** - Consultas agendadas
  - **Meus Pacientes** - Lista de pacientes atendidos
  - **Certificados Digitais** - Para assinatura de documentos

---

### 3.3 Recepcionista

**O que falar:**
> "A recepcionista é o ponto de entrada do paciente na unidade de saúde. Ela faz o check-in, gerencia a fila de espera, registra demandas espontâneas e organiza o fluxo de atendimento."

**Demonstrar no sistema:**
- Login com: `rec_ma@telecuidar.com` / senha: `123`
- Mostrar o **Painel da Recepcionista**:
  - **Agenda do Dia** - Consultas agendadas
  - **Fila de Espera** - Pacientes aguardando atendimento
  - **Check-in** - Confirmar chegada do paciente
  - **Demanda Espontânea** - Registrar pacientes que chegaram sem agendamento

**Demonstrar Demanda Espontânea:**
1. Clicar em "Nova Demanda Espontânea"
2. Buscar paciente pelo nome ou CPF
3. Selecionar especialidade
4. Classificar urgência (Verde/Amarelo/Laranja/Vermelho)
5. Mostrar que o paciente entra na fila automaticamente

---

### 3.4 Assistente/Enfermeiro(a)

**O que falar:**
> "O assistente ou enfermeiro fica presencialmente com o paciente no consultório digital. Ele auxilia na captura de sinais vitais, orienta o uso dos equipamentos e dá suporte durante a teleconsulta."

**Demonstrar no sistema:**
- Login com: `enf_do@telecuidar.com` / senha: `123`
- Mostrar:
  - Painel com consultas do dia
  - Acesso à teleconsulta para auxiliar o paciente
  - Visualização dos sinais vitais capturados

---

### 3.5 Regulador Municipal

**O que falar:**
> "O regulador é um papel essencial no SUS. Ele organiza a fila de pacientes do município, prioriza casos urgentes, distribui os atendimentos entre os médicos disponíveis e garante que os recursos de saúde sejam utilizados de forma eficiente."

**Demonstrar no sistema:**
- Login com: `reg_go@telecuidar.com` / senha: `123`
- Mostrar o **Painel do Regulador**:
  - **Fila de Regulação** - Pacientes aguardando por especialidade
  - **Gestão de Pacientes** - Visualização completa dos pacientes do município
  - **Agendas** - Visualização das agendas de profissionais
  - **Priorização** - Classificação por urgência

**Funcionalidades do Regulador:**
- Visualizar demanda por especialidade
- Alocar pacientes em vagas disponíveis
- Priorizar atendimentos urgentes
- Acompanhar estatísticas do município

---

### 3.6 Paciente

**O que falar:**
> "O paciente tem acesso simplificado. Ele pode ver suas consultas agendadas, acessar a teleconsulta e visualizar seu histórico."

**Demonstrar no sistema:**
- Login com: `pac_maria@telecuidar.com` / senha: `123`
- Mostrar:
  - Painel do paciente
  - Consultas agendadas
  - Histórico de atendimentos

---

## PARTE 4: FLUXO COMPLETO DE TELECONSULTA (15 minutos)

### 4.1 Antes da Consulta

**O que falar:**
> "Vou demonstrar um fluxo completo de teleconsulta, desde o agendamento até a finalização."

**Demonstrar:**
1. Administrador cria agenda para o médico
2. Paciente é agendado
3. Paciente chega na unidade → Recepcionista faz check-in
4. Paciente entra no consultório digital

---

### 4.2 A Teleconsulta

**O que falar:**
> "Agora vou mostrar a teleconsulta em si. Esta é a tela que médico e paciente veem durante o atendimento."

**Demonstrar acessando uma teleconsulta:**

#### Área de Vídeo
- Videochamada em tempo real via Jitsi (servidor próprio)
- Controles de áudio e vídeo
- Opção de expandir tela

#### Barra Lateral - Abas Disponíveis

**Aba Anamnese:**
> "Aqui o médico registra a anamnese estruturada do paciente."
- Queixa Principal (QP)
- História da Doença Atual (HDA)
- História Patológica Pregressa (HPP)
- Antecedentes Pessoais e Familiares
- Hábitos de Vida

**Aba Histórico/Prontuário:**
> "O médico tem acesso ao prontuário eletrônico completo do paciente, com todas as consultas anteriores, documentos e evolução clínica."

**Aba Sinais Vitais:**
> "Os sinais vitais são capturados automaticamente dos dispositivos Bluetooth da maleta e aparecem em tempo real."
- Peso
- Altura / IMC
- Pressão Arterial (Sistólica/Diastólica)
- Frequência Cardíaca
- Saturação de Oxigênio (SpO₂)
- Temperatura

**Aba SOAP:**
> "O médico documenta usando o método SOAP, padrão internacional."
- S - Subjetivo (relato do paciente)
- O - Objetivo (exame físico)
- A - Avaliação (diagnóstico)
- P - Plano (conduta)

**Aba Receita:**
> "O médico pode emitir receitas digitais."
- Prescrição de medicamentos
- Formato padrão CFM

**Aba Atestado:**
> "Emissão de atestados médicos digitais."

**Aba Exame:**
> "Solicitação de exames complementares."

**Aba Laudo:**
> "Emissão de laudos médicos."

**Aba Encaminhamento:**
> "Encaminhamento para outras especialidades."

**Aba Retorno:**
> "Agendamento de consulta de retorno."

**Aba IA (Inteligência Artificial):**
> "Um dos diferenciais do TeleCuidar. A IA analisa todos os dados da consulta e gera:"
- **Resumo Clínico** - Síntese automática da consulta
- **Hipótese Diagnóstica** - Sugestões baseadas nos dados

**Aba CNS:**
> "Consulta ao Cartão Nacional de Saúde do paciente."

---

### 4.3 Dispositivos Médicos Conectados

**O que falar:**
> "A Maleta Itinerante é equipada com dispositivos médicos Bluetooth que enviam dados automaticamente para o sistema."

**Dispositivos suportados:**
- **Balança Digital** - Peso automaticamente capturado
- **Medidor de Pressão Omron** - PA e frequência cardíaca
- **Oxímetro** - Saturação de oxigênio
- **Termômetro Digital** - Temperatura

> "O diferencial é que o técnico não precisa digitar nada. Os dados aparecem automaticamente na tela do médico em tempo real."

---

### 4.4 Ausculta Remota

**O que falar:**
> "Um recurso inovador é a ausculta remota. Usando um estetoscópio digital, o som do coração e pulmão do paciente é transmitido para o médico ouvir em tempo real."

**Demonstrar:**
- Aba de Fonocardiograma/Ausculta
- Explicar que o áudio é transmitido com alta fidelidade
- O médico pode gravar e revisar

---

### 4.5 Finalização da Consulta

**O que falar:**
> "Ao finalizar, o médico clica em 'Finalizar Consulta'. Todos os documentos ficam salvos no prontuário do paciente."

**Demonstrar:**
- Botão "Finalizar Consulta"
- Avaliação Clínica
- Geração de documentos (receita, atestado, etc.)

---

## PARTE 5: RECURSOS DE GESTÃO (5 minutos)

### Relatórios e Métricas

**O que falar:**
> "O sistema gera relatórios completos para gestão."

**Mostrar:**
- Total de consultas realizadas
- Tempo médio de atendimento
- Consultas por especialidade
- Taxa de comparecimento

### Logs de Auditoria

**O que falar:**
> "Todas as ações no sistema são rastreadas para conformidade com LGPD e regulamentações de saúde."

---

## PARTE 6: SEGURANÇA E CONFORMIDADE (3 minutos)

**O que falar:**
> "O TeleCuidar foi desenvolvido seguindo as melhores práticas de segurança e conformidade:"

- **LGPD** - Proteção de dados pessoais
- **Resolução CFM 2.314/2022** - Regulamentação de telemedicina
- **Resolução CFM 1.638/2002** - Prontuário eletrônico
- **HTTPS** - Toda comunicação criptografada
- **Servidor Próprio de Vídeo** - Jitsi auto-hospedado, dados não passam por terceiros
- **Autenticação JWT** - Tokens seguros
- **Auditoria Completa** - Logs de todas as ações

---

## PARTE 7: EM DESENVOLVIMENTO (3 minutos)

**O que falar:**
> "Além das funcionalidades já operacionais, temos módulos em fase final de desenvolvimento:"

### 🔄 Integração com e-SUS
> "Estamos integrando o TeleCuidar com o e-SUS do Ministério da Saúde, permitindo que os dados de atendimento sejam automaticamente enviados para o sistema nacional."

### 📱 Confirmação de Agenda por WhatsApp
> "Pacientes receberão confirmação e lembretes de consulta via WhatsApp, reduzindo faltas e melhorando a adesão."

### 🛤️ Módulo de Linhas de Cuidado
> "Protocolos clínicos estruturados para acompanhamento longitudinal de condições crônicas como diabetes, hipertensão e saúde mental."

### 📚 Módulo de Treinamento
> "Plataforma de capacitação para técnicos e profissionais de saúde que vão operar o sistema."

---

## PARTE 8: ENCERRAMENTO (2 minutos)

**O que falar:**
> "O TeleCuidar é uma solução completa, pronta para produção, que já está em fase de POC (Prova de Conceito)."

> "Nosso objetivo é levar saúde especializada para quem mais precisa, usando tecnologia como ponte entre o médico e o paciente."

> "Estou à disposição para perguntas e para demonstrar qualquer funcionalidade em mais detalhes."

---

# 📝 CHECKLIST PRÉ-APRESENTAÇÃO

## Credenciais de Acesso

| Perfil | Email | Senha |
|--------|-------|-------|
| **Administrador** | adm_ca@telecuidar.com | 123 |
| **Médico** (Clínica Geral) | med_gt@telecuidar.com | 123 |
| **Médico** (Psiquiatria) | med_aj@telecuidar.com | 123 |
| **Enfermeira/Assistente** | enf_do@telecuidar.com | 123 |
| **Recepcionista** | rec_ma@telecuidar.com | 123 |
| **Regulador Municipal** | reg_go@telecuidar.com | 123 |
| **Paciente** (Maria Silva) | pac_maria@telecuidar.com | 123 |
| **Paciente** (João Santos) | pac_joao@telecuidar.com | 123 |
| **Paciente** (Ana Oliveira) | pac_ana@telecuidar.com | 123 |

## Verificações Técnicas

- [ ] Internet funcionando
- [ ] Acesso a https://www.telecuidar.com.br funcionando
- [ ] Testar login com cada perfil antes
- [ ] Verificar se há consultas agendadas para demonstração
- [ ] Testar videochamada
- [ ] Ter backup de capturas de tela caso internet falhe

## Equipamentos

- [ ] Notebook carregado
- [ ] Projetor/TV configurado
- [ ] Áudio funcionando (para mostrar ausculta)
- [ ] Mouse para navegação fluida

---

# 🎯 PONTOS-CHAVE PARA ENFATIZAR

1. **Solução Completa** - Não é apenas videochamada, é um sistema clínico completo
2. **Sem Digitação** - Dispositivos enviam dados automaticamente
3. **IA Integrada** - Análise inteligente auxilia o médico
4. **Servidor Próprio** - Dados não passam por terceiros
5. **Pronto para Produção** - Sistema já funcional, em fase de POC
6. **Escalável** - Pode atender múltiplas unidades simultaneamente

---

# ⚠️ PERGUNTAS FREQUENTES (PREPARE-SE)

**P: Os dados ficam seguros?**
> R: Sim, usamos criptografia HTTPS, servidor de vídeo próprio (Jitsi), e seguimos todas as normas da LGPD e CFM.

**P: Funciona com internet lenta?**
> R: O sistema foi otimizado para funcionar com conexões de baixa velocidade. A videochamada adapta a qualidade automaticamente.

**P: O médico precisa de equipamento especial?**
> R: Não, qualquer computador com câmera, microfone e navegador é suficiente.

**P: Como funciona a assinatura digital?**
> R: Integramos com certificados digitais padrão ICP-Brasil para assinatura de receitas e documentos.

**P: Já está sendo usado em algum lugar?**
> R: Estamos em fase de POC (Prova de Conceito) para validação em ambiente real.

---

*Documento preparado para apresentação do TeleCuidar - Fevereiro 2026*
