using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPatientResponsavelFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Adicionar campos de responsável legal na tabela PatientProfiles
            migrationBuilder.AddColumn<string>(
                name: "ResponsavelNome",
                table: "PatientProfiles",
                type: "TEXT",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResponsavelCpf",
                table: "PatientProfiles",
                type: "TEXT",
                maxLength: 14,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResponsavelTelefone",
                table: "PatientProfiles",
                type: "TEXT",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResponsavelEmail",
                table: "PatientProfiles",
                type: "TEXT",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResponsavelGrauParentesco",
                table: "PatientProfiles",
                type: "TEXT",
                maxLength: 50,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ResponsavelNome",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "ResponsavelCpf",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "ResponsavelTelefone",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "ResponsavelEmail",
                table: "PatientProfiles");

            migrationBuilder.DropColumn(
                name: "ResponsavelGrauParentesco",
                table: "PatientProfiles");
        }
    }
}
