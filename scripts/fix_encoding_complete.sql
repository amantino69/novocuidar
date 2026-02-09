-- Script de correção de encoding UTF-8 - TeleCuidar
-- Executa: docker exec telecuidar-postgres-dev psql -U postgres -d telecuidar -f /tmp/fix_encoding_complete.sql

-- Corrigir caracteres quebrados comuns
-- á → ?? 
-- é → ??
-- í → ??
-- ó → ??
-- ú → ??
-- ã → ??
-- õ → ??
-- ç → ??
-- ê → ??
-- â → ??

-- 1. Tabela Users - Name
UPDATE "Users" SET "Name" = REPLACE("Name", 'Cl??udio', 'Cláudio');
UPDATE "Users" SET "Name" = REPLACE("Name", 'Ant??nio', 'Antônio');
UPDATE "Users" SET "Name" = REPLACE("Name", 'Jo??o', 'João');
UPDATE "Users" SET "Name" = REPLACE("Name", 'Mar??a', 'María');
UPDATE "Users" SET "Name" = REPLACE("Name", 'L??cia', 'Lúcia');
UPDATE "Users" SET "Name" = REPLACE("Name", 'Jos??', 'José');

-- 2. Tabela HealthFacilities - NomeFantasia e RazaoSocial
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", '??rio', 'ário');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", '??o', 'ão');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", '??a', 'ça');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", '??e', 'ãe');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", 'Sa??de', 'Saúde');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", 'Fam??lia', 'Família');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", 'B??sica', 'Básica');
UPDATE "HealthFacilities" SET "NomeFantasia" = REPLACE("NomeFantasia", 'M??dica', 'Médica');

UPDATE "HealthFacilities" SET "RazaoSocial" = REPLACE("RazaoSocial", '??rio', 'ário');
UPDATE "HealthFacilities" SET "RazaoSocial" = REPLACE("RazaoSocial", '??o', 'ão');
UPDATE "HealthFacilities" SET "RazaoSocial" = REPLACE("RazaoSocial", '??a', 'ça');
UPDATE "HealthFacilities" SET "RazaoSocial" = REPLACE("RazaoSocial", 'Sa??de', 'Saúde');
UPDATE "HealthFacilities" SET "RazaoSocial" = REPLACE("RazaoSocial", 'Fam??lia', 'Família');

-- 3. Tabela Specialties - Name
UPDATE "Specialties" SET "Name" = REPLACE("Name", '??', 'á');

-- 4. Tabela Municipalities - Nome (não "Name")
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", '??o', 'ão') WHERE "Nome" LIKE '%??%';
UPDATE "Municipalities" SET "Nome" = 'Goiânia' WHERE "Nome" LIKE 'Goi%nia%';
UPDATE "Municipalities" SET "Nome" = 'Brasília' WHERE "Nome" LIKE 'Bras%lia%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'S??o', 'São') WHERE "Nome" LIKE '%S??o%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Rond??nia', 'Rondônia') WHERE "Nome" LIKE '%Rond%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Par??', 'Pará') WHERE "Nome" LIKE '%Par??%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Cear??', 'Ceará') WHERE "Nome" LIKE '%Cear%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Maranh??o', 'Maranhão') WHERE "Nome" LIKE '%Maranh%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Piau??', 'Piauí') WHERE "Nome" LIKE '%Piau%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Para??ba', 'Paraíba') WHERE "Nome" LIKE '%Para%ba%';
UPDATE "Municipalities" SET "Nome" = REPLACE("Nome", 'Amap??', 'Amapá') WHERE "Nome" LIKE '%Amap%';

-- 5. PatientProfiles - campos de texto
UPDATE "PatientProfiles" SET "MotherName" = REPLACE("MotherName", '??', 'ã') WHERE "MotherName" LIKE '%??%';
UPDATE "PatientProfiles" SET "FatherName" = REPLACE("FatherName", '??', 'ã') WHERE "FatherName" LIKE '%??%';
UPDATE "PatientProfiles" SET "Address" = REPLACE("Address", '??o', 'ão') WHERE "Address" LIKE '%??%';
UPDATE "PatientProfiles" SET "City" = REPLACE("City", '??o', 'ão') WHERE "City" LIKE '%??%';
UPDATE "PatientProfiles" SET "City" = REPLACE("City", 'Goi??nia', 'Goiânia') WHERE "City" LIKE '%Goi%';

-- 6. Appointments - campos de texto
UPDATE "Appointments" SET "Observation" = REPLACE("Observation", '??o', 'ão') WHERE "Observation" LIKE '%??%';
UPDATE "Appointments" SET "ReasonForVisit" = REPLACE("ReasonForVisit", '??o', 'ão') WHERE "ReasonForVisit" LIKE '%??%';
UPDATE "Appointments" SET "TriageNotes" = REPLACE("TriageNotes", '??o', 'ão') WHERE "TriageNotes" LIKE '%??%';

-- Verificação final
SELECT 'Users' as tabela, COUNT(*) as corrompidos FROM "Users" WHERE "Name" LIKE '%??%'
UNION ALL
SELECT 'HealthFacilities', COUNT(*) FROM "HealthFacilities" WHERE "NomeFantasia" LIKE '%??%'
UNION ALL
SELECT 'Municipalities', COUNT(*) FROM "Municipalities" WHERE "Nome" LIKE '%??%'
UNION ALL
SELECT 'Specialties', COUNT(*) FROM "Specialties" WHERE "Name" LIKE '%??%';
