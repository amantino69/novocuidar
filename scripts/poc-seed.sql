-- ============================================================
-- SCRIPT DE MASSA DE TESTES - POC TELECUIDAR
-- Data: 24/01/2026
-- Descrição: Cria base de dados organizada para POC
-- ============================================================

-- Limpar dados existentes (ordem importante por causa das FKs)
DELETE FROM Appointments;
DELETE FROM ProfessionalProfiles;
DELETE FROM PatientProfiles;
DELETE FROM Users;
DELETE FROM Specialties;

-- ============================================================
-- ESPECIALIDADES
-- ============================================================
INSERT INTO Specialties (Id, Name, Description, Status, CreatedAt, UpdatedAt, CustomFieldsJson) VALUES
('11111111-1111-1111-1111-111111111111', 'Cardiologia', 'Especialidade médica que trata doenças do coração e do sistema circulatório', 1, datetime('now'), datetime('now'), NULL),
('22222222-2222-2222-2222-222222222222', 'Psiquiatria', 'Especialidade médica que trata transtornos mentais e emocionais', 1, datetime('now'), datetime('now'), NULL),
('33333333-3333-3333-3333-333333333333', 'Clínica Geral', 'Atendimento médico geral e encaminhamentos', 1, datetime('now'), datetime('now'), NULL);

-- ============================================================
-- USUÁRIOS
-- Senha padrão: 123 (hash BCrypt)
-- ============================================================

-- Hash da senha "123"
-- $2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS

-- ADMINISTRADOR
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('ADM00001-0000-0000-0000-000000000001', 'adm_ca@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Cláudio', 'Amantino', '11111111111', '11999990001', NULL, 2, 1, 1, datetime('now'), datetime('now'));

-- MÉDICOS (Role = 1 = PROFESSIONAL)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('MED00001-0000-0000-0000-000000000001', 'med_aj@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Antônio', 'Jorge', '22222222222', '11999990002', NULL, 1, 1, 1, datetime('now'), datetime('now')),
('MED00002-0000-0000-0000-000000000002', 'med_gt@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Geraldo', 'Tadeu', '33333333333', '11999990003', NULL, 1, 1, 1, datetime('now'), datetime('now'));

-- ASSISTENTE (Role = 3 = ASSISTANT)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('ASS00001-0000-0000-0000-000000000001', 'enf_do@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Daniela', 'Ochoa', '44444444444', '11999990004', NULL, 3, 1, 1, datetime('now'), datetime('now'));

-- PACIENTES (Role = 0 = PATIENT)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('PAC00001-0000-0000-0000-000000000001', 'pac_dc@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Daniel', 'Carrara', '55555555555', '11999990005', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('PAC00002-0000-0000-0000-000000000002', 'pac_maria@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Maria', 'Silva', '66666666666', '11999990006', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('PAC00003-0000-0000-0000-000000000003', 'pac_joao@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'João', 'Santos', '77777777777', '11999990007', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('PAC00004-0000-0000-0000-000000000004', 'pac_ana@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Ana', 'Oliveira', '88888888888', '11999990008', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('PAC00005-0000-0000-0000-000000000005', 'pac_pedro@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Pedro', 'Costa', '99999999999', '11999990009', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('PAC00006-0000-0000-0000-000000000006', 'pac_lucia@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Lúcia', 'Ferreira', '10101010101', '11999990010', NULL, 0, 1, 1, datetime('now'), datetime('now'));

-- ============================================================
-- PERFIS PROFISSIONAIS
-- ============================================================
INSERT INTO ProfessionalProfiles (Id, UserId, SpecialtyId, Crm, Gender, BirthDate, CreatedAt, UpdatedAt) VALUES
('PROF0001-0000-0000-0000-000000000001', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'CRM-SP 123456', 'M', '1975-03-15', datetime('now'), datetime('now')),
('PROF0002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'CRM-SP 789012', 'M', '1968-07-22', datetime('now'), datetime('now'));

-- ============================================================
-- PERFIS DE PACIENTES
-- ============================================================
INSERT INTO PatientProfiles (Id, UserId, Gender, BirthDate, MotherName, CreatedAt, UpdatedAt) VALUES
('PATP0001-0000-0000-0000-000000000001', 'PAC00001-0000-0000-0000-000000000001', 'M', '1985-06-10', 'Helena Carrara', datetime('now'), datetime('now')),
('PATP0002-0000-0000-0000-000000000002', 'PAC00002-0000-0000-0000-000000000002', 'F', '1952-11-20', 'Josefa Silva', datetime('now'), datetime('now')),
('PATP0003-0000-0000-0000-000000000003', 'PAC00003-0000-0000-0000-000000000003', 'M', '1995-02-28', 'Rosa Santos', datetime('now'), datetime('now')),
('PATP0004-0000-0000-0000-000000000004', 'PAC00004-0000-0000-0000-000000000004', 'F', '1990-08-05', 'Marta Oliveira', datetime('now'), datetime('now')),
('PATP0005-0000-0000-0000-000000000005', 'PAC00005-0000-0000-0000-000000000005', 'M', '1978-12-12', 'Tereza Costa', datetime('now'), datetime('now')),
('PATP0006-0000-0000-0000-000000000006', 'PAC00006-0000-0000-0000-000000000006', 'F', '1965-04-30', 'Antônia Ferreira', datetime('now'), datetime('now'));

-- ============================================================
-- CONSULTAS REALIZADAS (30) - Status 4 = Completed
-- ============================================================

-- Daniel Carrara - Consultas com Dr. Geraldo (Cardiologia)
INSERT INTO Appointments (Id, PatientId, ProfessionalId, SpecialtyId, Date, Time, EndTime, Type, Status, Observation, CreatedAt, UpdatedAt, AnamnesisJson, SoapJson) VALUES
('CONS0001-0000-0000-0000-000000000001', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-05', '09:00:00', '09:30:00', 0, 4, 'Primeira consulta cardiológica. Paciente encaminhado para avaliação de rotina.', datetime('now'), datetime('now'), 
'{"queixaPrincipal":"Palpitações esporádicas","historiaDoencaAtual":"Paciente relata palpitações há 2 meses, principalmente após esforço físico","historicoFamiliar":"Pai faleceu de infarto aos 65 anos","medicamentosEmUso":"Nenhum","alergias":"Dipirona"}',
'{"subjetivo":"Paciente queixa-se de palpitações após esforço físico há 2 meses. Nega dor torácica, dispneia ou síncope.","objetivo":"PA: 130/85 mmHg, FC: 78 bpm, ausculta cardíaca sem sopros, ritmo regular","avaliacao":"Palpitações a esclarecer. Solicitar ECG e Holter 24h","plano":"1. ECG de repouso\n2. Holter 24h\n3. Retorno em 15 dias com exames"}'),

('CONS0002-0000-0000-0000-000000000002', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-10', '10:00:00', '10:30:00', 0, 4, 'Retorno com resultados de exames cardiológicos.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno com exames","historiaDoencaAtual":"Traz ECG e Holter. Refere melhora das palpitações","historicoFamiliar":"Pai com IAM","medicamentosEmUso":"Nenhum","alergias":"Dipirona"}',
'{"subjetivo":"Retorno com exames. Refere redução das palpitações após diminuir consumo de café.","objetivo":"PA: 125/80 mmHg, FC: 72 bpm. ECG: ritmo sinusal, sem alterações. Holter: extrassístoles atriais raras.","avaliacao":"Extrassístoles atriais benignas, provavelmente relacionadas a cafeína","plano":"1. Orientação para evitar cafeína e bebidas energéticas\n2. Atividade física regular\n3. Retorno em 3 meses ou se sintomas"}'),

('CONS0003-0000-0000-0000-000000000003', 'PAC00001-0000-0000-0000-000000000001', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-12', '14:00:00', '14:45:00', 0, 4, 'Avaliação psiquiátrica inicial.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Ansiedade e dificuldade para dormir","historiaDoencaAtual":"Paciente relata ansiedade há 6 meses, com piora nos últimos 2 meses. Insônia inicial.","historicoFamiliar":"Mãe com depressão","medicamentosEmUso":"Nenhum psiquiátrico","alergias":"Nenhuma conhecida"}',
'{"subjetivo":"Ansiedade intensa há 6 meses com piora recente. Insônia inicial, demora 2h para dormir. Preocupações excessivas com trabalho.","objetivo":"Paciente vigil, orientado, ansioso, sem alterações do pensamento, humor ansioso, afeto congruente.","avaliacao":"Transtorno de Ansiedade Generalizada (TAG) - F41.1","plano":"1. Iniciar Escitalopram 10mg 1x ao dia pela manhã\n2. Higiene do sono\n3. Psicoterapia recomendada\n4. Retorno em 30 dias"}'),

-- Maria Silva - Consultas com Dr. Geraldo (Cardiologia) - Paciente hipertensa
('CONS0004-0000-0000-0000-000000000004', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-06', '08:00:00', '08:30:00', 0, 4, 'Acompanhamento de hipertensão arterial.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Controle de pressão alta","historiaDoencaAtual":"Hipertensa há 15 anos, em uso regular de medicação. Refere bom controle.","historicoFamiliar":"Pai e mãe hipertensos","medicamentosEmUso":"Losartana 50mg 1x/dia, Anlodipino 5mg 1x/dia","alergias":"Penicilina"}',
'{"subjetivo":"Paciente em acompanhamento de HAS. Refere adesão medicamentosa, nega sintomas cardiovasculares.","objetivo":"PA: 135/85 mmHg, FC: 68 bpm, peso: 72kg. Ausculta cardíaca normal.","avaliacao":"Hipertensão arterial sistêmica controlada","plano":"1. Manter medicação atual\n2. Dieta hipossódica\n3. Caminhadas 30min/dia\n4. Retorno em 3 meses"}'),

('CONS0005-0000-0000-0000-000000000005', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-13', '09:30:00', '10:00:00', 0, 4, 'Reavaliação após ajuste medicamentoso.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno - ajuste de medicação","historiaDoencaAtual":"Voltou para reavaliar pressão após aumento de Losartana","historicoFamiliar":"HAS familiar","medicamentosEmUso":"Losartana 100mg 1x/dia, Anlodipino 5mg 1x/dia","alergias":"Penicilina"}',
'{"subjetivo":"Retorno após aumento de Losartana. Refere melhora do controle pressórico. Sem efeitos colaterais.","objetivo":"PA: 125/78 mmHg, FC: 70 bpm. Excelente resposta ao ajuste.","avaliacao":"HAS bem controlada com novo esquema","plano":"1. Manter Losartana 100mg + Anlodipino 5mg\n2. Solicitar exames de rotina (creatinina, potássio)\n3. Retorno em 3 meses"}'),

-- João Santos - Consultas com Dr. Antônio (Psiquiatria) - Paciente com ansiedade
('CONS0006-0000-0000-0000-000000000006', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-07', '15:00:00', '15:45:00', 0, 4, 'Primeira consulta - quadro ansioso.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Crises de ansiedade intensas","historiaDoencaAtual":"Paciente jovem com crises de pânico há 3 meses. Episódios de taquicardia, sudorese, medo de morrer.","historicoFamiliar":"Tia com síndrome do pânico","medicamentosEmUso":"Nenhum","alergias":"Nenhuma"}',
'{"subjetivo":"Crises de pânico típicas há 3 meses, 2-3x por semana, com evitação de locais fechados. Prejuízo funcional moderado.","objetivo":"Ansioso, taquicárdico leve (88bpm), sem outras alterações ao exame.","avaliacao":"Transtorno de Pânico - F41.0","plano":"1. Iniciar Sertralina 50mg pela manhã\n2. Clonazepam 0,5mg SOS (máx 2x/dia)\n3. Psicoterapia TCC urgente\n4. Retorno em 15 dias"}'),

('CONS0007-0000-0000-0000-000000000007', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-14', '16:00:00', '16:30:00', 0, 4, 'Retorno - avaliação de resposta medicamentosa.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno pânico","historiaDoencaAtual":"Retorno após início de Sertralina. Crises reduziram.","historicoFamiliar":"Tia com pânico","medicamentosEmUso":"Sertralina 50mg, Clonazepam 0,5mg SOS","alergias":"Nenhuma"}',
'{"subjetivo":"Melhora de 60% das crises. Usou Clonazepam apenas 2x na semana. Tolerando bem Sertralina. Náuseas leves nos primeiros dias.","objetivo":"Menos ansioso, FC: 76bpm. Humor eutímico.","avaliacao":"Boa resposta inicial ao tratamento do Transtorno de Pânico","plano":"1. Aumentar Sertralina para 100mg\n2. Manter Clonazepam SOS\n3. Continuar psicoterapia\n4. Retorno em 30 dias"}'),

-- Ana Oliveira - Consultas com Dr. Geraldo (Cardiologia) - Gestante
('CONS0008-0000-0000-0000-000000000008', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-08', '11:00:00', '11:30:00', 0, 4, 'Avaliação cardiológica pré-natal.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Avaliação cardíaca - gestante","historiaDoencaAtual":"Gestante 20 semanas, encaminhada pelo obstetra para avaliação de sopro cardíaco","historicoFamiliar":"Sem cardiopatias na família","medicamentosEmUso":"Ácido fólico, sulfato ferroso","alergias":"Nenhuma"}',
'{"subjetivo":"Gestante 20 semanas, assintomática cardiovascular. Obstetra detectou sopro e encaminhou.","objetivo":"PA: 110/70 mmHg, FC: 82 bpm. Sopro sistólico inocente 1+/6+, típico da gestação.","avaliacao":"Sopro inocente fisiológico da gestação. Sem cardiopatia estrutural.","plano":"1. Orientar que sopro é normal na gestação\n2. Ecocardiograma se persistir pós-parto\n3. Liberada para parto normal\n4. Sem restrições cardiovasculares"}'),

-- Pedro Costa - Consultas com Dr. Geraldo (Cardiologia) - Diabético
('CONS0009-0000-0000-0000-000000000009', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-09', '14:30:00', '15:00:00', 0, 4, 'Avaliação cardiovascular em diabético.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Check-up cardiovascular","historiaDoencaAtual":"Diabético tipo 2 há 10 anos, encaminhado pelo endocrinologista para avaliação cardiovascular","historicoFamiliar":"Pai diabético, faleceu de AVC","medicamentosEmUso":"Metformina 850mg 2x/dia, Glibenclamida 5mg 1x/dia, AAS 100mg","alergias":"Nenhuma"}',
'{"subjetivo":"Diabético há 10 anos, bom controle glicêmico. Encaminhado para estratificação de risco cardiovascular.","objetivo":"PA: 138/88 mmHg, FC: 74 bpm, IMC: 28. ECG: alterações inespecíficas de repolarização.","avaliacao":"DM2 com risco cardiovascular moderado. HAS associada.","plano":"1. Teste ergométrico\n2. Ecocardiograma\n3. Iniciar Losartana 50mg\n4. Reforçar dieta e exercícios\n5. Retorno com exames"}'),

('CONS0010-0000-0000-0000-000000000010', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-16', '15:00:00', '15:30:00', 0, 4, 'Retorno com resultados de exames.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno exames cardiológicos","historiaDoencaAtual":"Retorno com teste ergométrico e ecocardiograma","historicoFamiliar":"DM e AVC familiar","medicamentosEmUso":"Metformina, Glibenclamida, AAS, Losartana","alergias":"Nenhuma"}',
'{"subjetivo":"Retorno com exames. Aderente à Losartana, refere melhora da pressão em casa.","objetivo":"PA: 128/82 mmHg. TE: sem alterações isquêmicas, boa capacidade funcional. Eco: FE 62%, sem alterações estruturais.","avaliacao":"Baixo risco cardiovascular atual. DM2 e HAS controlados.","plano":"1. Manter tratamento atual\n2. Estatina: Atorvastatina 20mg\n3. Meta LDL < 70mg/dL\n4. Retorno em 6 meses"}'),

-- Lúcia Ferreira - Consultas com Dr. Antônio (Psiquiatria) - Depressão
('CONS0011-0000-0000-0000-000000000011', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-08', '10:00:00', '10:45:00', 0, 4, 'Avaliação inicial - quadro depressivo.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Tristeza e desânimo há meses","historiaDoencaAtual":"Paciente 60 anos, viúva há 1 ano. Tristeza persistente, choro fácil, isolamento social, insônia terminal.","historicoFamiliar":"Mãe teve depressão","medicamentosEmUso":"Losartana 50mg","alergias":"Sulfa"}',
'{"subjetivo":"Humor deprimido há 8 meses após viuvez. Anedonia, insônia terminal (acorda 4h e não dorme mais), perda de 5kg, ideação de morte passiva.","objetivo":"Hipovigil, higiene pessoal descuidada, humor deprimido, choro durante consulta, sem ideação suicida ativa.","avaliacao":"Episódio Depressivo Grave sem sintomas psicóticos - F32.2","plano":"1. Iniciar Venlafaxina 75mg pela manhã\n2. Mirtazapina 15mg à noite (insônia + apetite)\n3. Suporte familiar\n4. Retorno em 10 dias - urgência"}'),

('CONS0012-0000-0000-0000-000000000012', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-15', '11:00:00', '11:30:00', 0, 4, 'Retorno urgente - reavaliação depressão.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno depressão","historiaDoencaAtual":"Retorno em 7 dias. Refere sono melhor, mas humor ainda muito baixo.","historicoFamiliar":"Mãe depressiva","medicamentosEmUso":"Venlafaxina 75mg, Mirtazapina 15mg, Losartana","alergias":"Sulfa"}',
'{"subjetivo":"Sono melhorou com Mirtazapina, dorme a noite toda. Humor ainda deprimido, mas filha notou pequena melhora. Sem ideação de morte.","objetivo":"Melhor higiene, menos chorosa, afeto ainda constrito mas reativo.","avaliacao":"Depressão grave em início de resposta ao tratamento","plano":"1. Aumentar Venlafaxina para 150mg\n2. Manter Mirtazapina 15mg\n3. Acompanhamento familiar próximo\n4. Retorno em 15 dias"}'),

-- Mais consultas para completar 30 realizadas
('CONS0013-0000-0000-0000-000000000013', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-17', '09:00:00', '09:30:00', 0, 4, 'Consulta de seguimento cardiológico.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento","historiaDoencaAtual":"Retorno de rotina, sem queixas"}',
'{"subjetivo":"Paciente assintomático, sem palpitações desde última consulta.","objetivo":"PA: 120/78 mmHg, FC: 68 bpm, ausculta normal.","avaliacao":"Sem alterações cardiovasculares","plano":"Manter orientações, retorno em 6 meses"}'),

('CONS0014-0000-0000-0000-000000000014', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-18', '08:30:00', '09:00:00', 0, 4, 'Controle pressórico mensal.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Controle PA","historiaDoencaAtual":"Acompanhamento mensal de HAS"}',
'{"subjetivo":"Bom controle domiciliar, aferições entre 120-130/75-85.","objetivo":"PA: 128/82 mmHg, FC: 72 bpm.","avaliacao":"HAS controlada","plano":"Manter medicação, retorno em 2 meses"}'),

('CONS0015-0000-0000-0000-000000000015', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-19', '14:00:00', '14:30:00', 0, 4, 'Manutenção tratamento ansiedade.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento ansiedade","historiaDoencaAtual":"Manutenção do tratamento"}',
'{"subjetivo":"Crises de pânico cessaram. Usando Sertralina regularmente, não precisou de Clonazepam este mês.","objetivo":"Tranquilo, humor eutímico, sem ansiedade aparente.","avaliacao":"Transtorno de Pânico em remissão","plano":"Manter Sertralina 100mg, retorno em 60 dias"}'),

('CONS0016-0000-0000-0000-000000000016', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-20', '10:00:00', '10:30:00', 0, 4, 'Acompanhamento gestacional - cardiologia.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento gestação","historiaDoencaAtual":"Gestante 24 semanas, retorno cardiológico"}',
'{"subjetivo":"Assintomática, gestação evoluindo bem.","objetivo":"PA: 108/68 mmHg, FC: 84 bpm, sopro funcional mantido.","avaliacao":"Gestação de baixo risco cardiovascular","plano":"Alta cardiológica, retorno apenas se sintomas"}'),

('CONS0017-0000-0000-0000-000000000017', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-21', '14:00:00', '14:30:00', 0, 4, 'Controle DM e HAS.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Controle DM/HAS","historiaDoencaAtual":"Acompanhamento trimestral"}',
'{"subjetivo":"Glicemias em jejum 100-120, PA em casa bem controlada.","objetivo":"PA: 126/80 mmHg, FC: 70 bpm. Trouxe exames: HbA1c 6.8%, LDL 68.","avaliacao":"DM2 e HAS bem controlados, metas atingidas","plano":"Manter tratamento, parabéns pela adesão"}'),

('CONS0018-0000-0000-0000-000000000018', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-22', '10:00:00', '10:30:00', 0, 4, 'Melhora significativa depressão.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Melhora depressão","historiaDoencaAtual":"Retorno quinzenal"}',
'{"subjetivo":"Melhora de 70%. Voltou a sair de casa, retomou atividades, sono normalizado, recuperou 2kg.","objetivo":"Eutímica, sorridente, boa interação, afeto modulado.","avaliacao":"Depressão em franca remissão","plano":"Manter Venlafaxina 150mg e Mirtazapina 15mg por 6 meses, depois reavaliar"}'),

('CONS0019-0000-0000-0000-000000000019', 'PAC00001-0000-0000-0000-000000000001', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-23', '15:00:00', '15:30:00', 0, 4, 'Seguimento ansiedade.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento TAG","historiaDoencaAtual":"Retorno mensal"}',
'{"subjetivo":"Ansiedade controlada, dormindo bem, sem crises.","objetivo":"Calmo, sem sinais de ansiedade.","avaliacao":"TAG controlado","plano":"Manter Escitalopram 10mg, retorno em 60 dias"}'),

('CONS0020-0000-0000-0000-000000000020', 'PAC00002-0000-0000-0000-000000000002', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-11', '16:00:00', '16:45:00', 0, 4, 'Avaliação psiquiátrica complementar.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Insônia crônica","historiaDoencaAtual":"Encaminhada pelo cardiologista por insônia há anos"}',
'{"subjetivo":"Insônia inicial há 5 anos, demora 1-2h para dormir. Nega sintomas depressivos ou ansiosos significativos.","objetivo":"Vigil, orientada, humor eutímico, ansiosa leve.","avaliacao":"Insônia crônica primária","plano":"1. Higiene do sono\n2. Melatonina 3mg\n3. Evitar telas à noite\n4. Retorno em 30 dias"}'),

('CONS0021-0000-0000-0000-000000000021', 'PAC00003-0000-0000-0000-000000000003', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-15', '08:00:00', '08:30:00', 0, 4, 'Avaliação cardiológica pré-exercício.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Liberação para academia","historiaDoencaAtual":"Quer iniciar musculação, academia pediu avaliação"}',
'{"subjetivo":"Jovem saudável, quer iniciar atividade física, sem queixas cardiovasculares.","objetivo":"PA: 118/72 mmHg, FC: 66 bpm, ausculta normal, ECG sem alterações.","avaliacao":"Apto para atividade física sem restrições","plano":"Liberado para musculação e aeróbicos, sem limitações"}'),

('CONS0022-0000-0000-0000-000000000022', 'PAC00004-0000-0000-0000-000000000004', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-18', '14:00:00', '14:30:00', 0, 4, 'Avaliação ansiedade gestacional.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Ansiedade na gestação","historiaDoencaAtual":"Gestante ansiosa, preocupada com o parto"}',
'{"subjetivo":"Ansiedade leve relacionada à gestação, medo do parto, sem crises de pânico.","objetivo":"Ansiosa leve, sem critérios para transtorno.","avaliacao":"Ansiedade situacional da gestação","plano":"1. Psicoterapia breve\n2. Técnicas de relaxamento\n3. Sem medicação por ora\n4. Retorno se piorar"}'),

('CONS0023-0000-0000-0000-000000000023', 'PAC00005-0000-0000-0000-000000000005', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-01-19', '11:00:00', '11:30:00', 0, 4, 'Rastreio de depressão em diabético.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Rastreio depressão","historiaDoencaAtual":"Encaminhado pelo cardiologista para avaliar humor"}',
'{"subjetivo":"Nega sintomas depressivos, bom suporte familiar, aceita bem a doença.","objetivo":"Eutímico, afeto adequado, sem alterações.","avaliacao":"Sem transtorno psiquiátrico no momento","plano":"Não necessita acompanhamento, retorno apenas se sintomas"}'),

('CONS0024-0000-0000-0000-000000000024', 'PAC00006-0000-0000-0000-000000000006', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-01-20', '15:00:00', '15:30:00', 0, 4, 'Avaliação cardiológica em depressiva.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Palpitações","historiaDoencaAtual":"Palpitações desde início do antidepressivo, psiquiatra pediu avaliação"}',
'{"subjetivo":"Palpitações leves após início de Venlafaxina, sem outros sintomas.","objetivo":"PA: 125/80 mmHg, FC: 86 bpm, ritmo regular, ECG normal.","avaliacao":"Taquicardia sinusal leve por Venlafaxina, benigna","plano":"Tranquilizar, efeito esperado do medicamento, sem necessidade de suspender"}'),

('CONS0025-0000-0000-0000-000000000025', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2025-12-15', '09:00:00', '09:30:00', 0, 4, 'Consulta de dezembro - check-up.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Check-up anual","historiaDoencaAtual":"Avaliação cardiovascular de rotina"}',
'{"subjetivo":"Sem queixas, veio para check-up anual.","objetivo":"PA: 122/78, FC: 70, exame normal.","avaliacao":"Saudável cardiovascularmente","plano":"Manter hábitos saudáveis, retorno anual"}'),

('CONS0026-0000-0000-0000-000000000026', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2025-12-18', '10:00:00', '10:30:00', 0, 4, 'Ajuste medicamentoso HAS.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Pressão alta","historiaDoencaAtual":"Pressão subiu no frio"}',
'{"subjetivo":"Refere PA mais alta em casa nas últimas semanas de frio.","objetivo":"PA: 145/92 mmHg.","avaliacao":"Descontrole pressórico sazonal","plano":"Aumentar Losartana de 50 para 100mg"}'),

('CONS0027-0000-0000-0000-000000000027', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2025-12-20', '15:00:00', '15:30:00', 0, 4, 'Primeira consulta de dezembro.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Início tratamento","historiaDoencaAtual":"Primeira avaliação do transtorno de pânico"}',
'{"subjetivo":"Crises de pânico intensas, primeira vez buscando tratamento.","objetivo":"Muito ansioso.","avaliacao":"Transtorno de Pânico","plano":"Iniciar Sertralina e acompanhamento"}'),

('CONS0028-0000-0000-0000-000000000028', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2025-12-22', '11:00:00', '11:30:00', 0, 4, 'Primeira consulta gestante.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Avaliação gestacional","historiaDoencaAtual":"Primeira avaliação cardiológica na gestação"}',
'{"subjetivo":"Gestante 16 semanas, encaminhada para avaliação de sopro.","objetivo":"Sopro inocente.","avaliacao":"Normal para gestação","plano":"Orientações e alta"}'),

('CONS0029-0000-0000-0000-000000000029', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2025-12-28', '14:00:00', '14:30:00', 0, 4, 'Avaliação inicial diabético.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Avaliação cardiovascular","historiaDoencaAtual":"Diabético encaminhado para avaliação de risco"}',
'{"subjetivo":"DM2 há 10 anos, sem avaliação cardiológica prévia.","objetivo":"PA levemente elevada.","avaliacao":"Risco cardiovascular moderado","plano":"Exames e retorno"}'),

('CONS0030-0000-0000-0000-000000000030', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2025-12-30', '10:00:00', '10:45:00', 0, 4, 'Primeira consulta depressão.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Depressão grave","historiaDoencaAtual":"Viúva há 6 meses, depressão intensa"}',
'{"subjetivo":"Tristeza profunda, isolamento, perda de peso, insônia.","objetivo":"Muito deprimida.","avaliacao":"Depressão grave","plano":"Iniciar antidepressivos urgente"}');

-- ============================================================
-- CONSULTAS AGENDADAS (40) - Status 0 = Scheduled
-- Distribuídas em Fevereiro e Março de 2026
-- ============================================================

-- FEVEREIRO 2026 - 20 consultas
INSERT INTO Appointments (Id, PatientId, ProfessionalId, SpecialtyId, Date, Time, EndTime, Type, Status, CreatedAt, UpdatedAt) VALUES
-- Semana 1 Fevereiro (02-06)
('AGEN0001-0000-0000-0000-000000000001', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-02', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0002-0000-0000-0000-000000000002', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-02', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0003-0000-0000-0000-000000000003', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-03', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0004-0000-0000-0000-000000000004', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-03', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0005-0000-0000-0000-000000000005', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-04', '08:30:00', '09:00:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0006-0000-0000-0000-000000000006', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-04', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0007-0000-0000-0000-000000000007', 'PAC00001-0000-0000-0000-000000000001', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-05', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0008-0000-0000-0000-000000000008', 'PAC00002-0000-0000-0000-000000000002', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-05', '16:00:00', '16:30:00', 0, 0, datetime('now'), datetime('now')),

-- Semana 2 Fevereiro (09-13)
('AGEN0009-0000-0000-0000-000000000009', 'PAC00003-0000-0000-0000-000000000003', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-09', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0010-0000-0000-0000-000000000010', 'PAC00004-0000-0000-0000-000000000004', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-09', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0011-0000-0000-0000-000000000011', 'PAC00005-0000-0000-0000-000000000005', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-10', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0012-0000-0000-0000-000000000012', 'PAC00006-0000-0000-0000-000000000006', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-10', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),

-- Semana 3 Fevereiro (16-20)
('AGEN0013-0000-0000-0000-000000000013', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-16', '08:00:00', '08:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0014-0000-0000-0000-000000000014', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-17', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0015-0000-0000-0000-000000000015', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-18', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0016-0000-0000-0000-000000000016', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-19', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),

-- Semana 4 Fevereiro (23-27)
('AGEN0017-0000-0000-0000-000000000017', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-02-23', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0018-0000-0000-0000-000000000018', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-24', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0019-0000-0000-0000-000000000019', 'PAC00001-0000-0000-0000-000000000001', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-25', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0020-0000-0000-0000-000000000020', 'PAC00002-0000-0000-0000-000000000002', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-02-26', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now'));

-- MARÇO 2026 - 20 consultas
INSERT INTO Appointments (Id, PatientId, ProfessionalId, SpecialtyId, Date, Time, EndTime, Type, Status, CreatedAt, UpdatedAt) VALUES
-- Semana 1 Março (02-06)
('AGEN0021-0000-0000-0000-000000000021', 'PAC00003-0000-0000-0000-000000000003', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-02', '08:00:00', '08:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0022-0000-0000-0000-000000000022', 'PAC00004-0000-0000-0000-000000000004', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-02', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0023-0000-0000-0000-000000000023', 'PAC00005-0000-0000-0000-000000000005', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-03', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0024-0000-0000-0000-000000000024', 'PAC00006-0000-0000-0000-000000000006', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-03', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0025-0000-0000-0000-000000000025', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-04', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0026-0000-0000-0000-000000000026', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-05', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),

-- Semana 2 Março (09-13)
('AGEN0027-0000-0000-0000-000000000027', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-09', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0028-0000-0000-0000-000000000028', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-10', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0029-0000-0000-0000-000000000029', 'PAC00005-0000-0000-0000-000000000005', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-11', '08:30:00', '09:00:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0030-0000-0000-0000-000000000030', 'PAC00006-0000-0000-0000-000000000006', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-12', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),

-- Semana 3 Março (16-20)
('AGEN0031-0000-0000-0000-000000000031', 'PAC00001-0000-0000-0000-000000000001', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-16', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0032-0000-0000-0000-000000000032', 'PAC00002-0000-0000-0000-000000000002', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-17', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0033-0000-0000-0000-000000000033', 'PAC00003-0000-0000-0000-000000000003', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-18', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0034-0000-0000-0000-000000000034', 'PAC00004-0000-0000-0000-000000000004', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-19', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),

-- Semana 4 Março (23-27)
('AGEN0035-0000-0000-0000-000000000035', 'PAC00005-0000-0000-0000-000000000005', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-23', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0036-0000-0000-0000-000000000036', 'PAC00006-0000-0000-0000-000000000006', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-24', '08:00:00', '08:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0037-0000-0000-0000-000000000037', 'PAC00001-0000-0000-0000-000000000001', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-25', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0038-0000-0000-0000-000000000038', 'PAC00002-0000-0000-0000-000000000002', 'MED00002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', '2026-03-26', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0039-0000-0000-0000-000000000039', 'PAC00003-0000-0000-0000-000000000003', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-30', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AGEN0040-0000-0000-0000-000000000040', 'PAC00004-0000-0000-0000-000000000004', 'MED00001-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', '2026-03-31', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now'));

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
