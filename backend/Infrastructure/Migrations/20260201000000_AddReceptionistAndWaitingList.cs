using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddReceptionistAndWaitingList : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Adicionar novos campos em Appointments
            migrationBuilder.AddColumn<Guid>(
                name: "AssistantId",
                table: "Appointments",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CheckInTime",
                table: "Appointments",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ConsultationStartedAt",
                table: "Appointments",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DoctorJoinedAt",
                table: "Appointments",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ConsultationEndedAt",
                table: "Appointments",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DurationInMinutes",
                table: "Appointments",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "NotificationsSentCount",
                table: "Appointments",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastNotificationSentAt",
                table: "Appointments",
                type: "TEXT",
                nullable: true);

            // Criar tabela WaitingLists
            migrationBuilder.CreateTable(
                name: "WaitingLists",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    AppointmentId = table.Column<Guid>(type: "TEXT", nullable: false),
                    PatientId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ProfessionalId = table.Column<Guid>(type: "TEXT", nullable: false),
                    UnityId = table.Column<Guid>(type: "TEXT", nullable: true),
                    Position = table.Column<int>(type: "INTEGER", nullable: false),
                    Priority = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    CheckInTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CalledTime = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CallAttempts = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    Status = table.Column<int>(type: "INTEGER", nullable: false, defaultValue: 0),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaitingLists", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WaitingLists_Appointments_AppointmentId",
                        column: x => x.AppointmentId,
                        principalTable: "Appointments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WaitingLists_Users_PatientId",
                        column: x => x.PatientId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WaitingLists_Users_ProfessionalId",
                        column: x => x.ProfessionalId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            // Criar índices
            migrationBuilder.CreateIndex(
                name: "IX_WaitingLists_Status_Position",
                table: "WaitingLists",
                columns: new[] { "Status", "Position" });

            migrationBuilder.CreateIndex(
                name: "IX_WaitingLists_CheckInTime",
                table: "WaitingLists",
                column: "CheckInTime");

            migrationBuilder.CreateIndex(
                name: "IX_WaitingLists_AppointmentId",
                table: "WaitingLists",
                column: "AppointmentId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WaitingLists_PatientId",
                table: "WaitingLists",
                column: "PatientId");

            migrationBuilder.CreateIndex(
                name: "IX_WaitingLists_ProfessionalId",
                table: "WaitingLists",
                column: "ProfessionalId");

            migrationBuilder.CreateIndex(
                name: "IX_Appointments_AssistantId",
                table: "Appointments",
                column: "AssistantId");

            // Criar foreign key para Assistant
            migrationBuilder.AddForeignKey(
                name: "FK_Appointments_Users_AssistantId",
                table: "Appointments",
                column: "AssistantId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Remover foreign keys
            migrationBuilder.DropForeignKey(
                name: "FK_Appointments_Users_AssistantId",
                table: "Appointments");

            // Remover tabela WaitingLists
            migrationBuilder.DropTable(
                name: "WaitingLists");

            // Remover índices
            migrationBuilder.DropIndex(
                name: "IX_Appointments_AssistantId",
                table: "Appointments");

            // Remover colunas de Appointments
            migrationBuilder.DropColumn(
                name: "AssistantId",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "CheckInTime",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "ConsultationStartedAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "DoctorJoinedAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "ConsultationEndedAt",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "DurationInMinutes",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "NotificationsSentCount",
                table: "Appointments");

            migrationBuilder.DropColumn(
                name: "LastNotificationSentAt",
                table: "Appointments");
        }
    }
}
