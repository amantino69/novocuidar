-- Performance indexes for TeleCuidar
-- Run with: docker exec -i telecuidar-postgres psql -U postgres -d telecuidar < add_indexes.sql

-- Indexes for Appointments table
CREATE INDEX IF NOT EXISTS "IX_Appointments_PatientId" ON "Appointments" ("PatientId");
CREATE INDEX IF NOT EXISTS "IX_Appointments_ProfessionalId" ON "Appointments" ("ProfessionalId");
CREATE INDEX IF NOT EXISTS "IX_Appointments_Date" ON "Appointments" ("Date");
CREATE INDEX IF NOT EXISTS "IX_Appointments_Status" ON "Appointments" ("Status");
CREATE INDEX IF NOT EXISTS "IX_Appointments_Date_Status" ON "Appointments" ("Date", "Status");

-- Indexes for Schedules table
CREATE INDEX IF NOT EXISTS "IX_Schedules_IsActive" ON "Schedules" ("IsActive");
CREATE INDEX IF NOT EXISTS "IX_Schedules_ProfessionalId" ON "Schedules" ("ProfessionalId");

-- Verify indexes were created
SELECT indexname, tablename FROM pg_indexes 
WHERE tablename IN ('Appointments', 'Schedules') 
ORDER BY tablename, indexname;
