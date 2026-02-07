-- Migração manual: Adiciona tabelas Municipality e HealthFacility
-- E colunas extras em PatientProfiles

-- 1. Criar tabela Municipalities
CREATE TABLE IF NOT EXISTS "Municipalities" (
    "Id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "CodigoIBGE" varchar(7) NOT NULL,
    "Nome" varchar(200) NOT NULL,
    "UF" varchar(2) NOT NULL,
    "Ativo" boolean NOT NULL DEFAULT true,
    "DataAdesao" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_Municipalities" PRIMARY KEY ("Id")
);

-- Índice único para CodigoIBGE
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Municipalities_CodigoIBGE" ON "Municipalities" ("CodigoIBGE");

-- 2. Criar tabela HealthFacilities
CREATE TABLE IF NOT EXISTS "HealthFacilities" (
    "Id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "CodigoCNES" varchar(20) NOT NULL,
    "NomeFantasia" varchar(200) NOT NULL,
    "RazaoSocial" varchar(300) NULL,
    "TipoEstabelecimento" varchar(50) NULL,
    "TipoEstabelecimentoDescricao" varchar(200) NULL,
    "CNPJ" varchar(18) NULL,
    "CEP" varchar(10) NULL,
    "Logradouro" varchar(200) NULL,
    "Numero" varchar(20) NULL,
    "Complemento" varchar(100) NULL,
    "Bairro" varchar(100) NULL,
    "Telefone" varchar(20) NULL,
    "Email" varchar(200) NULL,
    "Latitude" double precision NULL,
    "Longitude" double precision NULL,
    "TemConsultorioDigital" boolean NOT NULL DEFAULT false,
    "Ativo" boolean NOT NULL DEFAULT true,
    "UltimaSincronizacaoCNES" timestamp with time zone NULL,
    "MunicipioId" uuid NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PK_HealthFacilities" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_HealthFacilities_Municipalities_MunicipioId" FOREIGN KEY ("MunicipioId") 
        REFERENCES "Municipalities" ("Id") ON DELETE CASCADE
);

-- Índices para HealthFacilities
CREATE UNIQUE INDEX IF NOT EXISTS "IX_HealthFacilities_CodigoCNES" ON "HealthFacilities" ("CodigoCNES");
CREATE INDEX IF NOT EXISTS "IX_HealthFacilities_MunicipioId" ON "HealthFacilities" ("MunicipioId");

-- 3. Adicionar colunas em PatientProfiles (se não existirem)
DO $$
BEGIN
    -- ESusId
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='ESusId') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "ESusId" varchar(100) NULL;
    END IF;
    
    -- RacaCor
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='RacaCor') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "RacaCor" varchar(50) NULL;
    END IF;
    
    -- Logradouro
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='Logradouro') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "Logradouro" varchar(200) NULL;
    END IF;
    
    -- Numero
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='Numero') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "Numero" varchar(20) NULL;
    END IF;
    
    -- Complemento
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='Complemento') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "Complemento" varchar(100) NULL;
    END IF;
    
    -- Bairro
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='Bairro') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "Bairro" varchar(100) NULL;
    END IF;
    
    -- MunicipioId
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='MunicipioId') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "MunicipioId" uuid NULL;
    END IF;
    
    -- UnidadeAdscritaId
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='PatientProfiles' AND column_name='UnidadeAdscritaId') THEN
        ALTER TABLE "PatientProfiles" ADD COLUMN "UnidadeAdscritaId" uuid NULL;
    END IF;
END $$;

-- Índices para as novas colunas em PatientProfiles
CREATE INDEX IF NOT EXISTS "IX_PatientProfiles_MunicipioId" ON "PatientProfiles" ("MunicipioId");
CREATE INDEX IF NOT EXISTS "IX_PatientProfiles_UnidadeAdscritaId" ON "PatientProfiles" ("UnidadeAdscritaId");

-- Foreign keys para PatientProfiles (sem SET NULL - PostgreSQL não suporta ON DELETE SET NULL em ADD CONSTRAINT facilmente)
-- Vamos criar as FKs separadamente usando DEFERRABLE
DO $$
BEGIN
    -- FK para Municipality
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'FK_PatientProfiles_Municipalities_MunicipioId') THEN
        ALTER TABLE "PatientProfiles" 
        ADD CONSTRAINT "FK_PatientProfiles_Municipalities_MunicipioId" 
        FOREIGN KEY ("MunicipioId") REFERENCES "Municipalities" ("Id") ON DELETE SET NULL;
    END IF;
    
    -- FK para HealthFacility
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'FK_PatientProfiles_HealthFacilities_UnidadeAdscritaId') THEN
        ALTER TABLE "PatientProfiles" 
        ADD CONSTRAINT "FK_PatientProfiles_HealthFacilities_UnidadeAdscritaId" 
        FOREIGN KEY ("UnidadeAdscritaId") REFERENCES "HealthFacilities" ("Id") ON DELETE SET NULL;
    END IF;
END $$;

-- Registrar migração no histórico do EF
INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260207080000_AddMunicipalityAndHealthFacility', '8.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;
