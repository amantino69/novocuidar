-- ============================================================
-- SCRIPT PARA CRIAR ANEXOS DAS CONSULTAS POC
-- TELECUIDAR - 24/01/2026
-- ============================================================
-- Tipos de anexos:
-- - Resultados de exames (ECG, Holter, Hemograma, etc.)
-- - Receituários
-- - Laudos
-- - Encaminhamentos

-- ============================================================
-- ANEXOS - DANIEL CARRARA (71E0E646)
-- ============================================================

-- ECG - Consulta cardio inicial
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  '5A1B2C3D-4E5F-6A7B-8C9D-0E1F2A3B4C5D',
  '7815A758-5E15-4B86-B0CB-2A5AF007F643',
  'Eletrocardiograma de Repouso',
  'ecg_repouso_15012026.pdf',
  '/attachments/2026/01/ecg_repouso_15012026.pdf',
  'application/pdf',
  245760,
  '2026-01-05 11:30:00',
  '2026-01-05 11:30:00'
);

-- Holter 24h - Retorno cardio
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  '6B2C3D4E-5F6A-7B8C-9D0E-1F2A3B4C5D6E',
  '2FCA8FFE-EC90-4BA3-A4F9-AF28D64D9220',
  'Holter 24 horas - Laudo',
  'holter_24h_laudo_10012026.pdf',
  '/attachments/2026/01/holter_24h_laudo_10012026.pdf',
  'application/pdf',
  512000,
  '2026-01-10 10:30:00',
  '2026-01-10 10:30:00'
);

-- Receituário ansiolítico - Consulta psiquiatria
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  '7C3D4E5F-6A7B-8C9D-0E1F-2A3B4C5D6E7F',
  '7F5E0A3E-7D24-440C-BE35-1A6983C25B89',
  'Receituário - Escitalopram',
  'receita_escitalopram_12012026.pdf',
  '/attachments/2026/01/receita_escitalopram_12012026.pdf',
  'application/pdf',
  102400,
  '2026-01-12 15:30:00',
  '2026-01-12 15:30:00'
);

-- ============================================================
-- ANEXOS - MARIA SILVA (F764F4E1)
-- ============================================================

-- Exames laboratoriais - Ajuste HAS
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  '8D4E5F6A-7B8C-9D0E-1F2A-3B4C5D6E7F8A',
  '9A876D14-92B1-4943-92B7-C0C08A01D923',
  'Exames Laboratoriais - Função Renal e Eletrólitos',
  'lab_funcao_renal_18122025.pdf',
  '/attachments/2025/12/lab_funcao_renal_18122025.pdf',
  'application/pdf',
  156000,
  '2025-12-18 11:00:00',
  '2025-12-18 11:00:00'
);

-- Perfil lipídico - Controle HAS
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  '9E5F6A7B-8C9D-0E1F-2A3B-4C5D6E7F8A9B',
  'ADC227DF-9C3B-498A-A92D-B1BB0DA3B91B',
  'Perfil Lipídico Completo',
  'perfil_lipidico_06012026.pdf',
  '/attachments/2026/01/perfil_lipidico_06012026.pdf',
  'application/pdf',
  128000,
  '2026-01-06 09:00:00',
  '2026-01-06 09:00:00'
);

-- Receituário anti-hipertensivos
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'AE6F7A8B-9C0D-1E2F-3A4B-5C6D7E8F9A0B',
  'E705B3BA-0E09-4D10-9BFA-94DFCFE1EAF1',
  'Receituário - Anti-hipertensivos',
  'receita_anti_hipertensivos_13012026.pdf',
  '/attachments/2026/01/receita_anti_hipertensivos_13012026.pdf',
  'application/pdf',
  98304,
  '2026-01-13 10:00:00',
  '2026-01-13 10:00:00'
);

-- Receituário para insônia
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'BF7A8B9C-0D1E-2F3A-4B5C-6D7E8F9A0B1C',
  '561F08B5-6DCD-47E4-BCA4-1F93FED65A9B',
  'Receituário - Zolpidem',
  'receita_zolpidem_11012026.pdf',
  '/attachments/2026/01/receita_zolpidem_11012026.pdf',
  'application/pdf',
  87040,
  '2026-01-11 17:00:00',
  '2026-01-11 17:00:00'
);

-- ============================================================
-- ANEXOS - JOÃO SANTOS (AE637012)
-- ============================================================

-- Receituário ISRS + Benzodiazepínico
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'C08B9C0D-1E2F-3A4B-5C6D-7E8F9A0B1C2D',
  '028DBAD0-2E50-430A-A1A3-8D20C6BF1F28',
  'Receituário B - Sertralina e Clonazepam',
  'receita_b_sertralina_clonazepam_07012026.pdf',
  '/attachments/2026/01/receita_b_sertralina_clonazepam_07012026.pdf',
  'application/pdf',
  115712,
  '2026-01-07 16:00:00',
  '2026-01-07 16:00:00'
);

-- Atestado para academia
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'D19C0D1E-2F3A-4B5C-6D7E-8F9A0B1C2D3E',
  '5D5ECF04-41D0-4613-8FF4-54343D54E654',
  'Atestado de Aptidão Física para Academia',
  'atestado_academia_15012026.pdf',
  '/attachments/2026/01/atestado_academia_15012026.pdf',
  'application/pdf',
  76800,
  '2026-01-15 09:00:00',
  '2026-01-15 09:00:00'
);

-- Escalas psicométricas
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'E20D1E2F-3A4B-5C6D-7E8F-9A0B1C2D3E4F',
  'C9FB6D4A-531E-43E9-A423-5931F93E3FFD',
  'Escalas - PHQ-9 e GAD-7',
  'escalas_phq9_gad7_14012026.pdf',
  '/attachments/2026/01/escalas_phq9_gad7_14012026.pdf',
  'application/pdf',
  184320,
  '2026-01-14 17:00:00',
  '2026-01-14 17:00:00'
);

-- ============================================================
-- ANEXOS - ANA OLIVEIRA (BA040C1B) - GESTANTE
-- ============================================================

-- Ecocardiograma
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'F31E2F3A-4B5C-6D7E-8F9A-0B1C2D3E4F5A',
  'CECCDB6C-CC87-439B-8238-1883FBABC740',
  'Ecocardiograma Transtorácico',
  'ecocardiograma_08012026.pdf',
  '/attachments/2026/01/ecocardiograma_08012026.pdf',
  'application/pdf',
  768000,
  '2026-01-08 12:00:00',
  '2026-01-08 12:00:00'
);

-- ECG gestacional
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'A42F3A4B-5C6D-7E8F-9A0B-1C2D3E4F5A6B',
  'CECCDB6C-CC87-439B-8238-1883FBABC740',
  'ECG de Repouso - Gestante',
  'ecg_gestacional_08012026.pdf',
  '/attachments/2026/01/ecg_gestacional_08012026.pdf',
  'application/pdf',
  204800,
  '2026-01-08 12:30:00',
  '2026-01-08 12:30:00'
);

-- Laudo de aptidão cardíaca para gestação
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'B53A4B5C-6D7E-8F9A-0B1C-2D3E4F5A6B7C',
  '3C8FAB75-8E28-4FF8-9F0C-DB5D74D2358D',
  'Laudo - Aptidão Cardiovascular para Gestação',
  'laudo_aptidao_cardio_gestacao_20012026.pdf',
  '/attachments/2026/01/laudo_aptidao_cardio_gestacao_20012026.pdf',
  'application/pdf',
  153600,
  '2026-01-20 11:00:00',
  '2026-01-20 11:00:00'
);

-- ============================================================
-- ANEXOS - PEDRO COSTA (E7657BF8) - DIABÉTICO
-- ============================================================

-- Hemoglobina glicada
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'C64B5C6D-7E8F-9A0B-1C2D-3E4F5A6B7C8D',
  '6F65F999-198B-405E-834D-5036DED973AB',
  'Hemoglobina Glicada (HbA1c)',
  'hba1c_28122025.pdf',
  '/attachments/2025/12/hba1c_28122025.pdf',
  'application/pdf',
  92160,
  '2025-12-28 15:00:00',
  '2025-12-28 15:00:00'
);

-- Perfil lipídico DM
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'D75C6D7E-8F9A-0B1C-2D3E-4F5A6B7C8D9E',
  '3AE49CF2-3991-4CEA-B82F-6999873D244B',
  'Perfil Lipídico Completo',
  'perfil_lipidico_dm_09012026.pdf',
  '/attachments/2026/01/perfil_lipidico_dm_09012026.pdf',
  'application/pdf',
  134144,
  '2026-01-09 15:00:00',
  '2026-01-09 15:00:00'
);

-- Função renal
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'E86D7E8F-9A0B-1C2D-3E4F-5A6B7C8D9E0F',
  '3AE49CF2-3991-4CEA-B82F-6999873D244B',
  'Função Renal - Clearance Creatinina',
  'funcao_renal_09012026.pdf',
  '/attachments/2026/01/funcao_renal_09012026.pdf',
  'application/pdf',
  110592,
  '2026-01-09 15:00:00',
  '2026-01-09 15:00:00'
);

-- ECG + Eco
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'F97E8F9A-0B1C-2D3E-4F5A-6B7C8D9E0F1A',
  '9EF50898-1B84-4B3A-92A4-4D98ADA8FBB0',
  'ECG e Ecocardiograma - Estratificação Cardiovascular',
  'ecg_eco_dm_16012026.pdf',
  '/attachments/2026/01/ecg_eco_dm_16012026.pdf',
  'application/pdf',
  921600,
  '2026-01-16 16:00:00',
  '2026-01-16 16:00:00'
);

-- Receituário DM/HAS
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'A08F9A0B-1C2D-3E4F-5A6B-7C8D9E0F1A2B',
  '16E81A55-7410-4895-8B73-FAD28E8A1CF2',
  'Receituário - Metformina, Glibenclamida, AAS',
  'receita_dm_has_21012026.pdf',
  '/attachments/2026/01/receita_dm_has_21012026.pdf',
  'application/pdf',
  98304,
  '2026-01-21 15:00:00',
  '2026-01-21 15:00:00'
);

-- ============================================================
-- ANEXOS - LÚCIA FERREIRA (903F9074) - DEPRESSÃO
-- ============================================================

-- Escalas de depressão
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'B19A0B1C-2D3E-4F5A-6B7C-8D9E0F1A2B3C',
  'CC218030-FFA3-4C16-A541-E3E531DADBB4',
  'Escalas - PHQ-9, HAM-D, Inventário Beck',
  'escalas_depressao_08012026.pdf',
  '/attachments/2026/01/escalas_depressao_08012026.pdf',
  'application/pdf',
  245760,
  '2026-01-08 11:00:00',
  '2026-01-08 11:00:00'
);

-- Receituário antidepressivo
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'C20B1C2D-3E4F-5A6B-7C8D-9E0F1A2B3C4D',
  'CC218030-FFA3-4C16-A541-E3E531DADBB4',
  'Receituário B - Mirtazapina 15mg',
  'receita_mirtazapina_08012026.pdf',
  '/attachments/2026/01/receita_mirtazapina_08012026.pdf',
  'application/pdf',
  102400,
  '2026-01-08 11:30:00',
  '2026-01-08 11:30:00'
);

-- Exames laboratoriais para exclusão de causas orgânicas
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'D31C2D3E-4F5A-6B7C-8D9E-0F1A2B3C4D5E',
  'B12A0B5B-BFBF-4845-9F26-15B8557E139C',
  'Função Tireoidiana e Hemograma',
  'tsh_hemograma_30122025.pdf',
  '/attachments/2025/12/tsh_hemograma_30122025.pdf',
  'application/pdf',
  167936,
  '2025-12-30 11:00:00',
  '2025-12-30 11:00:00'
);

-- Encaminhamento psicoterapia
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'E42D3E4F-5A6B-7C8D-9E0F-1A2B3C4D5E6F',
  'E0A037C7-1D6C-4D31-AC20-F8DDB44BC0B6',
  'Encaminhamento - Psicoterapia TCC',
  'encaminhamento_psicoterapia_15012026.pdf',
  '/attachments/2026/01/encaminhamento_psicoterapia_15012026.pdf',
  'application/pdf',
  81920,
  '2026-01-15 12:00:00',
  '2026-01-15 12:00:00'
);

-- ECG para avaliação palpitações
INSERT INTO Attachments (Id, AppointmentId, Title, FileName, FilePath, FileType, FileSize, CreatedAt, UpdatedAt)
VALUES (
  'F53E4F5A-6B7C-8D9E-0F1A-2B3C4D5E6F7A',
  'FDF34B8F-EB30-49AE-A8D7-9E3DE132289B',
  'ECG de Repouso - Avaliação Palpitações',
  'ecg_palpitacoes_20012026.pdf',
  '/attachments/2026/01/ecg_palpitacoes_20012026.pdf',
  'application/pdf',
  215040,
  '2026-01-20 16:00:00',
  '2026-01-20 16:00:00'
);

-- ============================================================
-- FIM DO SCRIPT DE ANEXOS
-- ============================================================
