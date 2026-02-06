-- Migration: AddReceptionistAndWaitingList
-- Data: 01/02/2026
-- Descrição: Adiciona perfil Recepcionista, fila de espera e novos campos em Appointments

-- ========================================
-- 1. Adicionar novos campos em Appointments
-- ========================================

ALTER TABLE "Appointments" ADD COLUMN "AssistantId" TEXT NULL;
ALTER TABLE "Appointments" ADD COLUMN "CheckInTime" TEXT NULL;
ALTER TABLE "Appointments" ADD COLUMN "ConsultationStartedAt" TEXT NULL;
ALTER TABLE "Appointments" ADD COLUMN "DoctorJoinedAt" TEXT NULL;
ALTER TABLE "Appointments" ADD COLUMN "ConsultationEndedAt" TEXT NULL;
ALTER TABLE "Appointments" ADD COLUMN "DurationInMinutes" INTEGER NULL;
ALTER TABLE "Appointments" ADD COLUMN "NotificationsSentCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Appointments" ADD COLUMN "LastNotificationSentAt" TEXT NULL;

-- ========================================
-- 2. Criar tabela WaitingLists
-- ========================================

CREATE TABLE "WaitingLists" (
    "Id" TEXT NOT NULL PRIMARY KEY,
    "AppointmentId" TEXT NOT NULL,
    "PatientId" TEXT NOT NULL,
    "ProfessionalId" TEXT NOT NULL,
    "UnityId" TEXT NULL,
    "Position" INTEGER NOT NULL,
    "Priority" INTEGER NOT NULL DEFAULT 0,
    "CheckInTime" TEXT NULL,
    "CalledTime" TEXT NULL,
    "CallAttempts" INTEGER NOT NULL DEFAULT 0,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "CreatedAt" TEXT NOT NULL,
    "UpdatedAt" TEXT NOT NULL,
    
    -- Foreign Keys
    CONSTRAINT "FK_WaitingLists_Appointments_AppointmentId" 
        FOREIGN KEY ("AppointmentId") 
        REFERENCES "Appointments"("Id") 
        ON DELETE CASCADE,
    
    CONSTRAINT "FK_WaitingLists_Users_PatientId" 
        FOREIGN KEY ("PatientId") 
        REFERENCES "Users"("Id") 
        ON DELETE RESTRICT,
    
    CONSTRAINT "FK_WaitingLists_Users_ProfessionalId" 
        FOREIGN KEY ("ProfessionalId") 
        REFERENCES "Users"("Id") 
        ON DELETE RESTRICT
);

-- ========================================
-- 3. Criar índices para otimização
-- ========================================

CREATE INDEX "IX_WaitingLists_AppointmentId" ON "WaitingLists" ("AppointmentId");
CREATE UNIQUE INDEX "IX_WaitingLists_AppointmentId_Unique" ON "WaitingLists" ("AppointmentId");
CREATE INDEX "IX_WaitingLists_PatientId" ON "WaitingLists" ("PatientId");
CREATE INDEX "IX_WaitingLists_ProfessionalId" ON "WaitingLists" ("ProfessionalId");
CREATE INDEX "IX_WaitingLists_Status_Position" ON "WaitingLists" ("Status", "Position");
CREATE INDEX "IX_WaitingLists_CheckInTime" ON "WaitingLists" ("CheckInTime");

-- ========================================
-- 4. Criar foreign key para AssistantId
-- ========================================

CREATE INDEX "IX_Appointments_AssistantId" ON "Appointments" ("AssistantId");

ALTER TABLE "Appointments" 
    ADD CONSTRAINT "FK_Appointments_Users_AssistantId" 
    FOREIGN KEY ("AssistantId") 
    REFERENCES "Users"("Id") 
    ON DELETE SET NULL;

-- ========================================
-- 5. Inserir registro de migration
-- ========================================

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260201000000_AddReceptionistAndWaitingList', '9.0.0');

-- ========================================
-- Verificação
-- ========================================

SELECT 'Migration aplicada com sucesso!' AS Status;
SELECT COUNT(*) AS TotalMigrations FROM "__EFMigrationsHistory";
