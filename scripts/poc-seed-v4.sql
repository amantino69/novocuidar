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
('7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', 'Cardiologia', 'Especialidade médica que trata doenças do coração e do sistema circulatório', 1, datetime('now'), datetime('now'), NULL),
('A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', 'Psiquiatria', 'Especialidade médica que trata transtornos mentais e emocionais', 1, datetime('now'), datetime('now'), NULL),
('0D833930-3B68-49A9-A3E7-E6407ECB91FD', 'Clínica Geral', 'Atendimento médico geral e encaminhamentos', 1, datetime('now'), datetime('now'), NULL);

-- ============================================================
-- USUÁRIOS
-- Senha padrão: 123 (hash BCrypt)
-- ============================================================

-- ADMINISTRADOR (Role = 2)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('A5FAAB8F-2F11-4F83-9CF0-4644063E46E2', 'adm_ca@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Cláudio', 'Amantino', '11111111111', '11999990001', NULL, 2, 1, 1, datetime('now'), datetime('now'));

-- MÉDICOS (Role = 1)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('03C7BB74-9BB2-48D6-8F6D-064376738F81', 'med_aj@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Antônio', 'Jorge', '22222222222', '11999990002', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('E85FB568-4BFF-46C8-A772-713899DE38AA', 'med_gt@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Geraldo', 'Tadeu', '33333333333', '11999990003', NULL, 0, 1, 1, datetime('now'), datetime('now'));

-- ASSISTENTE (Role = 3)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('0D56BC20-1EAC-4B58-A031-2D7AB4DB81E3', 'enf_do@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Daniela', 'Ochoa', '44444444444', '11999990004', NULL, 3, 1, 1, datetime('now'), datetime('now'));

-- PACIENTES (Role = 0)
INSERT INTO Users (Id, Email, PasswordHash, Name, LastName, Cpf, Phone, Avatar, Role, Status, EmailVerified, CreatedAt, UpdatedAt) VALUES
('71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'pac_dc@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Daniel', 'Carrara', '55555555555', '11999990005', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('F764F4E1-E999-4254-9272-FB1BAD994E59', 'pac_maria@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Maria', 'Silva', '66666666666', '11999990006', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('AE637012-D984-4583-8824-3EABB5911886', 'pac_joao@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'João', 'Santos', '77777777777', '11999990007', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'pac_ana@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Ana', 'Oliveira', '88888888888', '11999990008', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'pac_pedro@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Pedro', 'Costa', '99999999999', '11999990009', NULL, 0, 1, 1, datetime('now'), datetime('now')),
('903F9074-FA7B-492E-A670-44C827B4CFDD', 'pac_lucia@telecuidar.com', '$2a$12$G2KjeIvXtn9ZX.9lPu59Re6LgZ1smiJ2i.mQa304QNHCptj2ECnoS', 'Lúcia', 'Ferreira', '10101010101', '11999990010', NULL, 0, 1, 1, datetime('now'), datetime('now'));

-- ============================================================
-- PERFIS PROFISSIONAIS
-- ============================================================
INSERT INTO ProfessionalProfiles (Id, UserId, SpecialtyId, Crm, Gender, BirthDate, CreatedAt, UpdatedAt) VALUES
('C17A2785-2EFD-4C11-9E1F-71CD6D4441C1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', 'CRM-SP 123456', 'M', '1975-03-15', datetime('now'), datetime('now')),
('AB6C4130-675E-4050-BC2A-DF17CE88DC58', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', 'CRM-SP 789012', 'M', '1968-07-22', datetime('now'), datetime('now'));

-- ============================================================
-- PERFIS DE PACIENTES
-- ============================================================
INSERT INTO PatientProfiles (Id, UserId, Gender, BirthDate, MotherName, CreatedAt, UpdatedAt) VALUES
('8E8D5F51-B5A4-4C8B-8CED-AB2C9BD7D46A', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'M', '1985-06-10', 'Helena Carrara', datetime('now'), datetime('now')),
('7408A4AF-9436-4862-9551-6E77B6419E28', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'F', '1952-11-20', 'Josefa Silva', datetime('now'), datetime('now')),
('16F332CD-70C1-4326-9A9F-684B73BB67C9', 'AE637012-D984-4583-8824-3EABB5911886', 'M', '1995-02-28', 'Rosa Santos', datetime('now'), datetime('now')),
('1428291B-6EC5-4C32-9FBC-2EF44677DB91', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'F', '1990-08-05', 'Marta Oliveira', datetime('now'), datetime('now')),
('219FAD3C-9DFB-484D-A91A-68C7FD1D9738', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'M', '1978-12-12', 'Tereza Costa', datetime('now'), datetime('now')),
('D003CE52-BD92-4C28-A1E7-A6111885CC3A', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'F', '1965-04-30', 'Antônia Ferreira', datetime('now'), datetime('now'));

-- ============================================================
-- CONSULTAS REALIZADAS (30) - Status 4 = Completed
-- Médico Geraldo Tadeu (Cardio): e85fb568-4bff-46c8-a772-713899de38aa
-- Médico Antônio Jorge (Psiq): 03c7bb74-9bb2-48d6-8f6d-064376738f81
-- Especialidade Cardio: 7e0b0170-dfaa-4c28-b743-ae21ad5c0d59
-- Especialidade Psiq: a0f4cda0-6bf2-46e2-ab9f-15c72e137655
-- ============================================================

-- Daniel Carrara com Dr. Geraldo (Cardiologia)
INSERT INTO Appointments (Id, PatientId, ProfessionalId, SpecialtyId, Date, Time, EndTime, Type, Status, Observation, CreatedAt, UpdatedAt, AnamnesisJson, SoapJson) VALUES
('7815A758-5E15-4B86-B0CB-2A5AF007F643', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-05', '09:00:00', '09:30:00', 0, 4, 'Primeira consulta cardiológica. Paciente encaminhado para avaliação de rotina.', datetime('now'), datetime('now'), 
'{"queixaPrincipal":"Palpitações esporádicas","historiaDoencaAtual":"Paciente relata palpitações há 2 meses, principalmente após esforço físico","historicoFamiliar":"Pai faleceu de infarto aos 65 anos","medicamentosEmUso":"Nenhum","alergias":"Dipirona"}',
'{"subjetivo":"Paciente queixa-se de palpitações após esforço físico há 2 meses. Nega dor torácica, dispneia ou síncope.","objetivo":"PA: 130/85 mmHg, FC: 78 bpm, ausculta cardíaca sem sopros, ritmo regular","avaliacao":"Palpitações a esclarecer. Solicitar ECG e Holter 24h","plano":"1. ECG de repouso\n2. Holter 24h\n3. Retorno em 15 dias com exames"}'),

('2FCA8FFE-EC90-4BA3-A4F9-AF28D64D9220', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-10', '10:00:00', '10:30:00', 0, 4, 'Retorno com resultados de exames cardiológicos.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno com exames","historiaDoencaAtual":"Traz ECG e Holter. Refere melhora das palpitações","historicoFamiliar":"Pai com IAM","medicamentosEmUso":"Nenhum","alergias":"Dipirona"}',
'{"subjetivo":"Retorno com exames. Refere redução das palpitações após diminuir consumo de café.","objetivo":"PA: 125/80 mmHg, FC: 72 bpm. ECG: ritmo sinusal, sem alterações. Holter: extrassístoles atriais raras.","avaliacao":"Extrassístoles atriais benignas, provavelmente relacionadas a cafeína","plano":"1. Orientação para evitar cafeína e bebidas energéticas\n2. Atividade física regular\n3. Retorno em 3 meses ou se sintomas"}'),

-- Daniel Carrara com Dr. Antônio (Psiquiatria)
('7F5E0A3E-7D24-440C-BE35-1A6983C25B89', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-12', '14:00:00', '14:45:00', 0, 4, 'Avaliação psiquiátrica inicial.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Ansiedade e dificuldade para dormir","historiaDoencaAtual":"Paciente relata ansiedade há 6 meses, com piora nos últimos 2 meses. Insônia inicial.","historicoFamiliar":"Mãe com depressão","medicamentosEmUso":"Nenhum psiquiátrico","alergias":"Nenhuma conhecida"}',
'{"subjetivo":"Ansiedade intensa há 6 meses com piora recente. Insônia inicial, demora 2h para dormir. Preocupações excessivas com trabalho.","objetivo":"Paciente vigil, orientado, ansioso, sem alterações do pensamento, humor ansioso, afeto congruente.","avaliacao":"Transtorno de Ansiedade Generalizada (TAG) - F41.1","plano":"1. Iniciar Escitalopram 10mg 1x ao dia pela manhã\n2. Higiene do sono\n3. Psicoterapia recomendada\n4. Retorno em 30 dias"}'),

-- Maria Silva com Dr. Geraldo (Cardiologia) - Hipertensa
('ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-06', '08:00:00', '08:30:00', 0, 4, 'Acompanhamento de hipertensão arterial.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Controle de pressão alta","historiaDoencaAtual":"Hipertensa há 15 anos, em uso regular de medicação. Refere bom controle.","historicoFamiliar":"Pai e mãe hipertensos","medicamentosEmUso":"Losartana 50mg 1x/dia, Anlodipino 5mg 1x/dia","alergias":"Penicilina"}',
'{"subjetivo":"Paciente em acompanhamento de HAS. Refere adesão medicamentosa, nega sintomas cardiovasculares.","objetivo":"PA: 135/85 mmHg, FC: 68 bpm, peso: 72kg. Ausculta cardíaca normal.","avaliacao":"Hipertensão arterial sistêmica controlada","plano":"1. Manter medicação atual\n2. Dieta hipossódica\n3. Caminhadas 30min/dia\n4. Retorno em 3 meses"}'),

('E705B3BA-0E09-4D10-9BFA-94DFCFE1EAF1', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-13', '09:30:00', '10:00:00', 0, 4, 'Reavaliação após ajuste medicamentoso.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno - ajuste de medicação","historiaDoencaAtual":"Voltou para reavaliar pressão após aumento de Losartana","historicoFamiliar":"HAS familiar","medicamentosEmUso":"Losartana 100mg 1x/dia, Anlodipino 5mg 1x/dia","alergias":"Penicilina"}',
'{"subjetivo":"Retorno após aumento de Losartana. Refere melhora do controle pressórico. Sem efeitos colaterais.","objetivo":"PA: 125/78 mmHg, FC: 70 bpm. Excelente resposta ao ajuste.","avaliacao":"HAS bem controlada com novo esquema","plano":"1. Manter Losartana 100mg + Anlodipino 5mg\n2. Solicitar exames de rotina\n3. Retorno em 3 meses"}'),

-- João Santos com Dr. Antônio (Psiquiatria) - Ansiedade
('028DBAD0-2E50-430A-A1A3-8D20C6BF1F28', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-07', '15:00:00', '15:45:00', 0, 4, 'Primeira consulta - quadro ansioso.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Crises de ansiedade intensas","historiaDoencaAtual":"Paciente jovem com crises de pânico há 3 meses. Episódios de taquicardia, sudorese, medo de morrer.","historicoFamiliar":"Tia com síndrome do pânico","medicamentosEmUso":"Nenhum","alergias":"Nenhuma"}',
'{"subjetivo":"Crises de pânico típicas há 3 meses, 2-3x por semana, com evitação de locais fechados. Prejuízo funcional moderado.","objetivo":"Ansioso, taquicárdico leve (88bpm), sem outras alterações ao exame.","avaliacao":"Transtorno de Pânico - F41.0","plano":"1. Iniciar Sertralina 50mg pela manhã\n2. Clonazepam 0,5mg SOS\n3. Psicoterapia TCC urgente\n4. Retorno em 15 dias"}'),

('C9FB6D4A-531E-43E9-A423-5931F93E3FFD', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-14', '16:00:00', '16:30:00', 0, 4, 'Retorno - avaliação de resposta medicamentosa.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno pânico","historiaDoencaAtual":"Retorno após início de Sertralina. Crises reduziram.","historicoFamiliar":"Tia com pânico","medicamentosEmUso":"Sertralina 50mg, Clonazepam 0,5mg SOS","alergias":"Nenhuma"}',
'{"subjetivo":"Melhora de 60% das crises. Usou Clonazepam apenas 2x na semana. Tolerando bem Sertralina.","objetivo":"Menos ansioso, FC: 76bpm. Humor eutímico.","avaliacao":"Boa resposta inicial ao tratamento do Transtorno de Pânico","plano":"1. Aumentar Sertralina para 100mg\n2. Manter Clonazepam SOS\n3. Continuar psicoterapia\n4. Retorno em 30 dias"}'),

-- Ana Oliveira com Dr. Geraldo (Cardiologia) - Gestante
('CECCDB6C-CC87-439B-8238-1883FBABC740', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-08', '11:00:00', '11:30:00', 0, 4, 'Avaliação cardiológica pré-natal.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Avaliação cardíaca - gestante","historiaDoencaAtual":"Gestante 20 semanas, encaminhada pelo obstetra para avaliação de sopro cardíaco","historicoFamiliar":"Sem cardiopatias na família","medicamentosEmUso":"Ácido fólico, sulfato ferroso","alergias":"Nenhuma"}',
'{"subjetivo":"Gestante 20 semanas, assintomática cardiovascular. Obstetra detectou sopro e encaminhou.","objetivo":"PA: 110/70 mmHg, FC: 82 bpm. Sopro sistólico inocente 1+/6+, típico da gestação.","avaliacao":"Sopro inocente fisiológico da gestação. Sem cardiopatia estrutural.","plano":"1. Orientar que sopro é normal na gestação\n2. Ecocardiograma se persistir pós-parto\n3. Liberada para parto normal"}'),

-- Pedro Costa com Dr. Geraldo (Cardiologia) - Diabético
('3AE49CF2-3991-4CEA-B82F-6999873D244B', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-09', '14:30:00', '15:00:00', 0, 4, 'Avaliação cardiovascular em diabético.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Check-up cardiovascular","historiaDoencaAtual":"Diabético tipo 2 há 10 anos, encaminhado pelo endocrinologista","historicoFamiliar":"Pai diabético, faleceu de AVC","medicamentosEmUso":"Metformina 850mg 2x/dia, Glibenclamida 5mg 1x/dia, AAS 100mg","alergias":"Nenhuma"}',
'{"subjetivo":"Diabético há 10 anos, bom controle glicêmico. Encaminhado para estratificação de risco cardiovascular.","objetivo":"PA: 138/88 mmHg, FC: 74 bpm, IMC: 28. ECG: alterações inespecíficas.","avaliacao":"DM2 com risco cardiovascular moderado. HAS associada.","plano":"1. Teste ergométrico\n2. Ecocardiograma\n3. Iniciar Losartana 50mg\n4. Retorno com exames"}'),

('9EF50898-1B84-4B3A-92A4-4D98ADA8FBB0', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-16', '15:00:00', '15:30:00', 0, 4, 'Retorno com resultados de exames.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno exames cardiológicos","historiaDoencaAtual":"Retorno com teste ergométrico e ecocardiograma","historicoFamiliar":"DM e AVC familiar","medicamentosEmUso":"Metformina, Glibenclamida, AAS, Losartana","alergias":"Nenhuma"}',
'{"subjetivo":"Retorno com exames. Aderente à Losartana, refere melhora da pressão em casa.","objetivo":"PA: 128/82 mmHg. TE: sem alterações isquêmicas. Eco: FE 62%, sem alterações.","avaliacao":"Baixo risco cardiovascular atual. DM2 e HAS controlados.","plano":"1. Manter tratamento atual\n2. Atorvastatina 20mg\n3. Retorno em 6 meses"}'),

-- Lúcia Ferreira com Dr. Antônio (Psiquiatria) - Depressão
('CC218030-FFA3-4C16-A541-E3E531DADBB4', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-08', '10:00:00', '10:45:00', 0, 4, 'Avaliação inicial - quadro depressivo.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Tristeza e desânimo há meses","historiaDoencaAtual":"Paciente 60 anos, viúva há 1 ano. Tristeza persistente, choro fácil, isolamento social, insônia terminal.","historicoFamiliar":"Mãe teve depressão","medicamentosEmUso":"Losartana 50mg","alergias":"Sulfa"}',
'{"subjetivo":"Humor deprimido há 8 meses após viuvez. Anedonia, insônia terminal, perda de 5kg, ideação de morte passiva.","objetivo":"Hipovigil, higiene pessoal descuidada, humor deprimido, choro durante consulta.","avaliacao":"Episódio Depressivo Grave sem sintomas psicóticos - F32.2","plano":"1. Iniciar Venlafaxina 75mg\n2. Mirtazapina 15mg à noite\n3. Suporte familiar\n4. Retorno em 10 dias - urgência"}'),

('E0A037C7-1D6C-4D31-AC20-F8DDB44BC0B6', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-15', '11:00:00', '11:30:00', 0, 4, 'Retorno urgente - reavaliação depressão.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Retorno depressão","historiaDoencaAtual":"Retorno em 7 dias. Refere sono melhor, mas humor ainda baixo.","historicoFamiliar":"Mãe depressiva","medicamentosEmUso":"Venlafaxina 75mg, Mirtazapina 15mg, Losartana","alergias":"Sulfa"}',
'{"subjetivo":"Sono melhorou com Mirtazapina. Humor ainda deprimido, mas filha notou pequena melhora.","objetivo":"Melhor higiene, menos chorosa, afeto ainda constrito.","avaliacao":"Depressão grave em início de resposta ao tratamento","plano":"1. Aumentar Venlafaxina para 150mg\n2. Manter Mirtazapina 15mg\n3. Retorno em 15 dias"}'),

-- Mais consultas para completar 30
('42DF3E58-7995-424D-A85A-16EEB450CD64', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-17', '09:00:00', '09:30:00', 0, 4, 'Consulta de seguimento cardiológico.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento","historiaDoencaAtual":"Retorno de rotina, sem queixas"}',
'{"subjetivo":"Paciente assintomático, sem palpitações desde última consulta.","objetivo":"PA: 120/78 mmHg, FC: 68 bpm, ausculta normal.","avaliacao":"Sem alterações cardiovasculares","plano":"Manter orientações, retorno em 6 meses"}'),

('1D5C535A-902B-4A41-A754-2830510D1160', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-18', '08:30:00', '09:00:00', 0, 4, 'Controle pressórico mensal.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Controle PA","historiaDoencaAtual":"Acompanhamento mensal de HAS"}',
'{"subjetivo":"Bom controle domiciliar, aferições entre 120-130/75-85.","objetivo":"PA: 128/82 mmHg, FC: 72 bpm.","avaliacao":"HAS controlada","plano":"Manter medicação, retorno em 2 meses"}'),

('7F9989B8-B5D9-491D-ADF1-7EB3ED904FF2', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-19', '14:00:00', '14:30:00', 0, 4, 'Manutenção tratamento ansiedade.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento ansiedade","historiaDoencaAtual":"Manutenção do tratamento"}',
'{"subjetivo":"Crises de pânico cessaram. Usando Sertralina regularmente.","objetivo":"Tranquilo, humor eutímico, sem ansiedade.","avaliacao":"Transtorno de Pânico em remissão","plano":"Manter Sertralina 100mg, retorno em 60 dias"}'),

('3C8FAB75-8E28-4FF8-9F0C-DB5D74D2358D', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-20', '10:00:00', '10:30:00', 0, 4, 'Acompanhamento gestacional - cardiologia.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento gestação","historiaDoencaAtual":"Gestante 24 semanas, retorno cardiológico"}',
'{"subjetivo":"Assintomática, gestação evoluindo bem.","objetivo":"PA: 108/68 mmHg, FC: 84 bpm, sopro funcional mantido.","avaliacao":"Gestação de baixo risco cardiovascular","plano":"Alta cardiológica, retorno apenas se sintomas"}'),

('16E81A55-7410-4895-8B73-FAD28E8A1CF2', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-21', '14:00:00', '14:30:00', 0, 4, 'Controle DM e HAS.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Controle DM/HAS","historiaDoencaAtual":"Acompanhamento trimestral"}',
'{"subjetivo":"Glicemias em jejum 100-120, PA bem controlada.","objetivo":"PA: 126/80 mmHg, FC: 70 bpm. HbA1c 6.8%, LDL 68.","avaliacao":"DM2 e HAS bem controlados, metas atingidas","plano":"Manter tratamento, parabéns pela adesão"}'),

('E1194F79-CA05-479C-A381-32615CAB4C57', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-22', '10:00:00', '10:30:00', 0, 4, 'Melhora significativa depressão.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Melhora depressão","historiaDoencaAtual":"Retorno quinzenal"}',
'{"subjetivo":"Melhora de 70%. Voltou a sair de casa, retomou atividades, sono normalizado.","objetivo":"Eutímica, sorridente, boa interação.","avaliacao":"Depressão em franca remissão","plano":"Manter Venlafaxina 150mg e Mirtazapina 15mg por 6 meses"}'),

('19191513-7611-4B00-99E0-0AB4A1B67BA5', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-23', '15:00:00', '15:30:00', 0, 4, 'Seguimento ansiedade.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Seguimento TAG","historiaDoencaAtual":"Retorno mensal"}',
'{"subjetivo":"Ansiedade controlada, dormindo bem, sem crises.","objetivo":"Calmo, sem sinais de ansiedade.","avaliacao":"TAG controlado","plano":"Manter Escitalopram 10mg, retorno em 60 dias"}'),

('561F08B5-6DCD-47E4-BCA4-1F93FED65A9B', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-11', '16:00:00', '16:45:00', 0, 4, 'Avaliação psiquiátrica complementar.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Insônia crônica","historiaDoencaAtual":"Encaminhada pelo cardiologista por insônia há anos"}',
'{"subjetivo":"Insônia inicial há 5 anos, demora 1-2h para dormir.","objetivo":"Vigil, orientada, humor eutímico, ansiosa leve.","avaliacao":"Insônia crônica primária","plano":"1. Higiene do sono\n2. Melatonina 3mg\n3. Retorno em 30 dias"}'),

('5D5ECF04-41D0-4613-8FF4-54343D54E654', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-15', '08:00:00', '08:30:00', 0, 4, 'Avaliação cardiológica pré-exercício.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Liberação para academia","historiaDoencaAtual":"Quer iniciar musculação, academia pediu avaliação"}',
'{"subjetivo":"Jovem saudável, quer iniciar atividade física.","objetivo":"PA: 118/72 mmHg, FC: 66 bpm, ausculta normal, ECG normal.","avaliacao":"Apto para atividade física sem restrições","plano":"Liberado para musculação e aeróbicos"}'),

('6ECACC73-9EC2-4B76-8948-3AC89714BC2C', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-18', '14:00:00', '14:30:00', 0, 4, 'Avaliação ansiedade gestacional.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Ansiedade na gestação","historiaDoencaAtual":"Gestante ansiosa, preocupada com o parto"}',
'{"subjetivo":"Ansiedade leve relacionada à gestação, medo do parto.","objetivo":"Ansiosa leve, sem critérios para transtorno.","avaliacao":"Ansiedade situacional da gestação","plano":"1. Psicoterapia breve\n2. Técnicas de relaxamento\n3. Retorno se piorar"}'),

('CC3F489F-4531-4A0C-98D4-28D058C0E3FF', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-01-19', '11:00:00', '11:30:00', 0, 4, 'Rastreio de depressão em diabético.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Rastreio depressão","historiaDoencaAtual":"Encaminhado pelo cardiologista para avaliar humor"}',
'{"subjetivo":"Nega sintomas depressivos, bom suporte familiar.","objetivo":"Eutímico, afeto adequado.","avaliacao":"Sem transtorno psiquiátrico no momento","plano":"Não necessita acompanhamento, retorno se sintomas"}'),

('FDF34B8F-EB30-49AE-A8D7-9E3DE132289B', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-01-20', '15:00:00', '15:30:00', 0, 4, 'Avaliação cardiológica em depressiva.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Palpitações","historiaDoencaAtual":"Palpitações desde início do antidepressivo"}',
'{"subjetivo":"Palpitações leves após início de Venlafaxina.","objetivo":"PA: 125/80 mmHg, FC: 86 bpm, ritmo regular, ECG normal.","avaliacao":"Taquicardia sinusal leve por Venlafaxina, benigna","plano":"Tranquilizar, efeito esperado do medicamento"}'),

('9BA1FF25-71CE-44BE-A18F-71ECA2E39282', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-15', '09:00:00', '09:30:00', 0, 4, 'Consulta de dezembro - check-up.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Check-up anual","historiaDoencaAtual":"Avaliação cardiovascular de rotina"}',
'{"subjetivo":"Sem queixas, veio para check-up anual.","objetivo":"PA: 122/78, FC: 70, exame normal.","avaliacao":"Saudável cardiovascularmente","plano":"Manter hábitos saudáveis, retorno anual"}'),

('9A876D14-92B1-4943-92B7-C0C08A01D923', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-18', '10:00:00', '10:30:00', 0, 4, 'Ajuste medicamentoso HAS.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Pressão alta","historiaDoencaAtual":"Pressão subiu no frio"}',
'{"subjetivo":"Refere PA mais alta em casa nas últimas semanas de frio.","objetivo":"PA: 145/92 mmHg.","avaliacao":"Descontrole pressórico sazonal","plano":"Aumentar Losartana de 50 para 100mg"}'),

('0FBB3E67-D948-478F-99BB-4B42D1F86102', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2025-12-20', '15:00:00', '15:30:00', 0, 4, 'Primeira consulta de dezembro.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Início tratamento","historiaDoencaAtual":"Primeira avaliação do transtorno de pânico"}',
'{"subjetivo":"Crises de pânico intensas, primeira vez buscando tratamento.","objetivo":"Muito ansioso.","avaliacao":"Transtorno de Pânico","plano":"Iniciar Sertralina e acompanhamento"}'),

('C62C5612-05CC-437B-8A53-66A5D3C6A1F0', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-22', '11:00:00', '11:30:00', 0, 4, 'Primeira consulta gestante.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Avaliação gestacional","historiaDoencaAtual":"Primeira avaliação cardiológica na gestação"}',
'{"subjetivo":"Gestante 16 semanas, encaminhada para avaliação de sopro.","objetivo":"Sopro inocente.","avaliacao":"Normal para gestação","plano":"Orientações e alta"}'),

('6F65F999-198B-405E-834D-5036DED973AB', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2025-12-28', '14:00:00', '14:30:00', 0, 4, 'Avaliação inicial diabético.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Avaliação cardiovascular","historiaDoencaAtual":"Diabético encaminhado para avaliação de risco"}',
'{"subjetivo":"DM2 há 10 anos, sem avaliação cardiológica prévia.","objetivo":"PA levemente elevada.","avaliacao":"Risco cardiovascular moderado","plano":"Exames e retorno"}'),

('B12A0B5B-BFBF-4845-9F26-15B8557E139C', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2025-12-30', '10:00:00', '10:45:00', 0, 4, 'Primeira consulta depressão.', datetime('now'), datetime('now'),
'{"queixaPrincipal":"Depressão grave","historiaDoencaAtual":"Viúva há 6 meses, depressão intensa"}',
'{"subjetivo":"Tristeza profunda, isolamento, perda de peso, insônia.","objetivo":"Muito deprimida.","avaliacao":"Depressão grave","plano":"Iniciar antidepressivos urgente"}');

-- ============================================================
-- CONSULTAS AGENDADAS (40) - Status 0 = Scheduled
-- Fevereiro e Março de 2026
-- ============================================================

INSERT INTO Appointments (Id, PatientId, ProfessionalId, SpecialtyId, Date, Time, EndTime, Type, Status, CreatedAt, UpdatedAt) VALUES
-- FEVEREIRO 2026 - Semana 1
('7BF3B387-EEA2-4718-A856-619410E7025E', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-02', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('05C1D84F-DECF-4C8B-ACE6-0608FC203B02', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-02', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('0B53E10D-BC57-478F-9190-31CDDE8DAB62', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-03', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('5DFE7A57-770F-4128-AD9D-A9FFB510A957', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-03', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('4419B1C4-CF16-4805-8ECC-902000615462', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-04', '08:30:00', '09:00:00', 0, 0, datetime('now'), datetime('now')),
('F3CF97F7-D3EE-4FDC-8D7D-21AD9BFF3AA3', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-04', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('BB64ACC7-5E6D-43D1-B2FA-51EBF2F7BE0D', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-05', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('E6C6EF68-8015-419E-801A-274EB256CD38', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-05', '16:00:00', '16:30:00', 0, 0, datetime('now'), datetime('now'));

-- Gerar mais 32 consultas agendadas
INSERT INTO Appointments (Id, PatientId, ProfessionalId, SpecialtyId, Date, Time, EndTime, Type, Status, CreatedAt, UpdatedAt) VALUES
('5B5E0A35-3CA7-418C-97E8-7D08C595EE3D', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-09', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('831D1CD1-CD02-427A-A6EB-C60E1B197E58', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-09', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('7BB300AC-0C54-4961-8E80-5A58FF7174E4', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-10', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('162C4C74-183F-40F9-B0DC-BCF1195BFC8E', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-10', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('8E15DA52-D402-49CF-88E2-3A7A887C5C5D', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-16', '08:00:00', '08:30:00', 0, 0, datetime('now'), datetime('now')),
('6C30BCAA-42CC-428C-8B99-D27F498F1178', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-17', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('AD5E59BC-235B-42C0-ACCD-848748A2C3DB', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-18', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('2BFB1A24-5709-4FBF-8108-06447C8006CD', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-19', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('E563C87F-EE58-4F32-BE39-4E3B2FC3CE3B', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-02-23', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('3CE917A8-5EDF-4A03-BD72-8CB46D3050FB', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-24', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('9C6B917E-BB57-40A4-A9F4-584EF0DF5E34', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-25', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('FADE835C-8ABF-4DD4-B6A9-CB178105491C', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-02-26', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),

-- MARÇO 2026
('373C31E0-DC1E-48AC-9CBB-9859D8F7E401', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-02', '08:00:00', '08:30:00', 0, 0, datetime('now'), datetime('now')),
('D42B6E40-509C-4048-A44E-C57B5082340A', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-02', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('4780B0BD-E394-4579-9219-B53FD6D377D5', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-03', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('75CB5EC6-925B-41F7-9C12-280A77D54E02', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-03', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('FB930203-E186-4B28-8571-9262DDC27190', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-04', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('24F78DC6-1837-437E-B242-7B8E469EA915', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-05', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('52B4CE79-8584-4FC0-8512-0F602B73C985', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-09', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('27AFC103-D522-4675-9F08-03E49C01142B', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-10', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('4AE22444-56C5-4391-AE1D-B6E92844193D', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-11', '08:30:00', '09:00:00', 0, 0, datetime('now'), datetime('now')),
('C5E2818E-B8AA-44FE-9A5A-C0158CC8F5C4', '903F9074-FA7B-492E-A670-44C827B4CFDD', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-12', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('C660C9E9-402E-41A7-BA2E-F1FBCD7111E1', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-16', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('2AE2BD4F-F43D-4158-85ED-387A09E0D59B', 'F764F4E1-E999-4254-9272-FB1BAD994E59', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-17', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('3A7D9A9B-04A9-40F9-9E58-3AF461F532FB', 'AE637012-D984-4583-8824-3EABB5911886', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-18', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('A88AD97F-A0C7-4006-BD73-ACF31387431E', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-19', '11:00:00', '11:30:00', 0, 0, datetime('now'), datetime('now')),
('22C1758E-751C-47A8-B322-8368B09BD6B4', 'E7657BF8-9F97-4EF3-9FF3-48B02C2F8A52', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-23', '15:00:00', '15:30:00', 0, 0, datetime('now'), datetime('now')),
('15DA9D4D-A6C5-4884-B1C3-ED042921926D', '903F9074-FA7B-492E-A670-44C827B4CFDD', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-24', '08:00:00', '08:30:00', 0, 0, datetime('now'), datetime('now')),
('52E7626E-3C79-47FE-99D8-FB87B551DA5F', '71E0E646-73FA-4838-B73B-9E9C9CAAB4BA', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-25', '10:00:00', '10:30:00', 0, 0, datetime('now'), datetime('now')),
('C4F55712-CD54-4879-B223-2D19C50A71C6', 'F764F4E1-E999-4254-9272-FB1BAD994E59', 'E85FB568-4BFF-46C8-A772-713899DE38AA', '7E0B0170-DFAA-4C28-B743-AE21AD5C0D59', '2026-03-26', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now')),
('88B5B102-7CE8-4234-9787-DAA555E03F6C', 'AE637012-D984-4583-8824-3EABB5911886', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-30', '09:00:00', '09:30:00', 0, 0, datetime('now'), datetime('now')),
('62734EF5-C2AF-40F1-8726-099932DA0240', 'BA040C1B-869F-4307-AA80-C6EFC83D95D1', '03C7BB74-9BB2-48D6-8F6D-064376738F81', 'A0F4CDA0-6BF2-46E2-AB9F-15C72E137655', '2026-03-31', '14:00:00', '14:30:00', 0, 0, datetime('now'), datetime('now'));

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
