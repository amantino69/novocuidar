using System;
using Npgsql;

var connectionString = "Host=localhost;Port=5432;Database=telecuidar;Username=postgres;Password=postgres";

Console.WriteLine("🔧 Iniciando aplicação da migration...\n");

var sql = @"
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""AssistantId"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""CheckInTime"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""ConsultationStartedAt"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""DoctorJoinedAt"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""ConsultationEndedAt"" TEXT NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""DurationInMinutes"" INTEGER NULL;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""NotificationsSentCount"" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE ""Appointments"" ADD COLUMN IF NOT EXISTS ""LastNotificationSentAt"" TEXT NULL;

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
    Console.WriteLine("✅ Conectado ao PostgreSQL\n");
    
    using var command = new NpgsqlCommand(sql, connection);
    command.ExecuteNonQuery();
    Console.WriteLine("✅ Colunas e tabelas criadas\n");
    
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
    Console.WriteLine("✅ Índices criados\n");
    
    // Adicionar foreign keys
    var fks = new[] {
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_waitinglists_appointments_appointmentid') THEN
                ALTER TABLE ""WaitingLists"" ADD CONSTRAINT ""FK_WaitingLists_Appointments_AppointmentId"" 
                    FOREIGN KEY (""AppointmentId"") REFERENCES ""Appointments""(""Id"") ON DELETE CASCADE;
            END IF;
        END $$;",
        
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_waitinglists_users_patientid') THEN
                ALTER TABLE ""WaitingLists"" ADD CONSTRAINT ""FK_WaitingLists_Users_PatientId"" 
                    FOREIGN KEY (""PatientId"") REFERENCES ""Users""(""Id"") ON DELETE RESTRICT;
            END IF;
        END $$;",
        
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_waitinglists_users_professionalid') THEN
                ALTER TABLE ""WaitingLists"" ADD CONSTRAINT ""FK_WaitingLists_Users_ProfessionalId"" 
                    FOREIGN KEY (""ProfessionalId"") REFERENCES ""Users""(""Id"") ON DELETE RESTRICT;
            END IF;
        END $$;",
        
        @"DO $$ 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_appointments_users_assistantid') THEN
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
    Console.WriteLine("✅ Foreign keys criadas\n");
    
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
    Console.WriteLine("✅ Migration registrada\n");
    
    Console.WriteLine("🎉 MIGRATION APLICADA COM SUCESSO!");
    Console.WriteLine("\nPode iniciar o backend agora: dotnet run --project backend/WebAPI/WebAPI.csproj");
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Erro: {ex.Message}");
    Console.WriteLine($"Stack: {ex.StackTrace}");
    return 1;
}

return 0;
