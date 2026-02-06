using Microsoft.EntityFrameworkCore.Migrations;

namespace Infrastructure.Data.Migrations;

public partial class AddAbandonedStatusAndLastActivity : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        // Adicionar coluna LastActivityAt à tabela Appointments
        migrationBuilder.AddColumn<DateTime>(
            name: "LastActivityAt",
            table: "Appointments",
            type: "timestamp with time zone",
            nullable: true,
            comment: "Última atividade registrada na consulta (para timeout de abandono)");

        // Backfill LastActivityAt com UpdatedAt para consultas em InProgress (status 3)
        migrationBuilder.Sql(
            @"UPDATE public.""Appointments"" 
              SET ""LastActivityAt"" = ""UpdatedAt"" 
              WHERE ""Status"" = 3 AND ""LastActivityAt"" IS NULL");

        migrationBuilder.Sql(
            @"UPDATE public.""Appointments"" 
              SET ""LastActivityAt"" = ""CreatedAt"" 
              WHERE ""Status"" = 3 AND ""LastActivityAt"" IS NULL");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "LastActivityAt",
            table: "Appointments");
    }
}
