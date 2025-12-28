using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDigitalCertificates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DigitalCertificates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "TEXT", nullable: false),
                    UserId = table.Column<Guid>(type: "TEXT", nullable: false),
                    DisplayName = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Subject = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    Issuer = table.Column<string>(type: "TEXT", maxLength: 500, nullable: false),
                    Thumbprint = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    CpfFromCertificate = table.Column<string>(type: "TEXT", maxLength: 14, nullable: true),
                    NameFromCertificate = table.Column<string>(type: "TEXT", maxLength: 300, nullable: true),
                    ExpirationDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    IssuedDate = table.Column<DateTime>(type: "TEXT", nullable: false),
                    EncryptedPfxBase64 = table.Column<string>(type: "TEXT", nullable: false),
                    QuickUseEnabled = table.Column<bool>(type: "INTEGER", nullable: false),
                    EncryptedPassword = table.Column<string>(type: "TEXT", nullable: true),
                    EncryptionIV = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    LastUsedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DigitalCertificates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DigitalCertificates_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DigitalCertificates_Thumbprint",
                table: "DigitalCertificates",
                column: "Thumbprint");

            migrationBuilder.CreateIndex(
                name: "IX_DigitalCertificates_UserId",
                table: "DigitalCertificates",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DigitalCertificates");
        }
    }
}
