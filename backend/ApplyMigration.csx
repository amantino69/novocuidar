using Npgsql;

var connectionString = "Host=localhost;Port=5432;Database=telecuidar;Username=postgres;Password=postgres";

var sql = @"
-- Adicionar novos campos em Appointments
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""AssistantId"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""CheckInTime"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""ConsultationStartedAt"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""DoctorJoinedAt"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""ConsultationEndedAt"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""DurationInMinutes"" INTEGER NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""NotificationsSentCount"" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""LastNotificationSentAt"" TEXT NULL;

-- Criar tabela WaitingLists se não existir
CREATE TABLE IF NOT EXISTS ""WaitingLists"" (
    ""Id"" TEXT NOT NULL PRIMARY KEY,
    ""AppointmentId"" TEXT NOT NULL,
    ""PatientId"" TEXT NOT NULL,
    ""ProfessionalId"" TEXT NOT NULL,
    ""UnityId"" TEXT NULL,
    ""Position"" INTEGER NOT NULL,
    ""Priority"" INTEGER NOT NULL DEFAULT 0,
    ""CheckInTime"" TEXT NULL,
    ""CalledTime"" TEXT NULL,
    ""CallAttempts"" INTEGER NOT NULL DEFAULT 0,
    ""Status"" INTEGER NOT NULL DEFAULT 0,
    ""CreatedAt"" TEXT NOT NULL,
    ""UpdatedAt"" TEXT NOT NULL
);
";

try
{
    using var connection = new NpgsqlConnection(connectionString);
    connection.Open();
    
    using var command = new NpgsqlCommand(sql, connection);
    command.ExecuteNonQuery();
    
    Console.WriteLine("✅ Migration aplicada com sucesso!");
    
    // Criar índices
    var indexes = new[] {
        @"CREATE INDEX IF NOT EXISTS ""IX_WaitingLists_AppointmentId"" ON ""WaitingLists"" (""AppointmentId"");",
        @"CREATE INDEX IF NOT EXISTS ""IX_WaitingLists_PatientId"" ON ""WaitingLists"" (""PatientId"");",
        @"CREATE INDEX IF NOT EXISTS ""IX_WaitingLists_ProfessionalId"" ON ""WaitingLists"" (""ProfessionalId"");",
        @"CREATE INDEX IF NOT EXISTS ""IX_WaitingLists_Status_Position"" ON ""WaitingLists"" (""Status"", ""Position"");",
        @"CREATE INDEX IF NOT EXISTS ""IX_Appointments_AssistantId"" ON ""Appointments"" (""AssistantId"");"
    };
    
    foreach (var index in indexes)
    {
        using var cmd = new NpgsqlCommand(index, connection);
        cmd.ExecuteNonQuery();
    }
    
    Console.WriteLine("✅ Índices criados!");
    
    // Adicionar foreign keys
    var fks = new[] {
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_WaitingLists_Appointments_AppointmentId') THEN
                ALTER TABLE ""WaitingLists"" ADD CONSTRAINT ""FK_WaitingLists_Appointments_AppointmentId"" 
                    FOREIGN KEY (""AppointmentId"") REFERENCES ""Appointments""(""Id"") ON DELETE CASCADE;
            END IF;
        END $$;",
        
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_WaitingLists_Users_PatientId') THEN
                ALTER TABLE ""WaitingLists"" ADD CONSTRAINT ""FK_WaitingLists_Users_PatientId"" 
                    FOREIGN KEY (""PatientId"") REFERENCES ""Users""(""Id"") ON DELETE RESTRICT;
            END IF;
        END $$;",
        
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_WaitingLists_Users_ProfessionalId') THEN
                ALTER TABLE ""WaitingLists"" ADD CONSTRAINT ""FK_WaitingLists_Users_ProfessionalId"" 
                    FOREIGN KEY (""ProfessionalId"") REFERENCES ""Users""(""Id"") ON DELETE RESTRICT;
            END IF;
        END $$;",
        
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_Appointments_Users_AssistantId') THEN
                ALTER TABLE ""Appointments"" ADD CONSTRAINT ""FK_Appointments_Users_AssistantId"" 
                    FOREIGN KEY (""AssistantId"") REFERENCES ""Users""(""Id"") ON DELETE SET NULL;
            END IF;
        END $$;"
    };
    
    foreach (var fk in fks)
    {
        using var cmd = new NpgsqlCommand(fk, connection);
        cmd.ExecuteNonQuery();
    }
    
    Console.WriteLine("✅ Foreign keys criadas!");
    
    // Registrar migration
    var insertMigration = @"
        INSERT INTO ""__EFMigrationsHistory"" (""MigrationId"", ""ProductVersion"")
        SELECT '20260201000000_AddReceptionistAndWaitingList', '9.0.0'
        WHERE NOT EXISTS (
            SELECT 1 FROM ""__EFMigrationsHistory"" 
            WHERE ""MigrationId"" = '20260201000000_AddReceptionistAndWaitingList'
        );";
    
    using (var cmd = new NpgsqlCommand(insertMigration, connection))
    {
        cmd.ExecuteNonQuery();
    }
    
    Console.WriteLine("✅ Migration registrada!");
    Console.WriteLine("\n🎉 TUDO PRONTO! Pode iniciar o backend agora.");
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Erro: {ex.Message}");
    return 1;
}

return 0;
