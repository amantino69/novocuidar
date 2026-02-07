-- Migration: AddPatientResponsavelFields
-- Data: 2026-02-07
-- Descrição: Adiciona campos de responsável legal para pacientes

-- Adicionar colunas (PostgreSQL usa IF NOT EXISTS para evitar erro se já existir)
DO $$ 
BEGIN
    -- ResponsavelNome
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='ResponsavelNome') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "ResponsavelNome" VARCHAR(255) NULL;
    END IF;
    
    -- ResponsavelCpf
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='ResponsavelCpf') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "ResponsavelCpf" VARCHAR(14) NULL;
    END IF;
    
    -- ResponsavelTelefone
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='ResponsavelTelefone') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "ResponsavelTelefone" VARCHAR(20) NULL;
    END IF;
    
    -- ResponsavelEmail
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='ResponsavelEmail') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "ResponsavelEmail" VARCHAR(255) NULL;
    END IF;
    
    -- ResponsavelGrauParentesco
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='ResponsavelGrauParentesco') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "ResponsavelGrauParentesco" VARCHAR(50) NULL;
    END IF;
END $$;

-- Registrar migration (se usar EF migrations)
INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
SELECT '20260207000000_AddPatientResponsavelFields', '8.0.0'
WHERE NOT EXISTS (
    SELECT 1 FROM "__EFMigrationsHistory" 
    WHERE "MigrationId" = '20260207000000_AddPatientResponsavelFields'
);

-- Verificar resultado
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'PatientProfiles' 
AND column_name LIKE 'Responsavel%';
