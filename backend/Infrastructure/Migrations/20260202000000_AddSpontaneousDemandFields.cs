using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSpontaneousDemandFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Adicionar campos de demanda espontânea na tabela WaitingLists
            migrationBuilder.AddColumn<bool>(
                name: "IsSpontaneousDemand",
                table: "WaitingLists",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "UrgencyLevel",
                table: "WaitingLists",
                type: "INTEGER",
                nullable: true,
                defaultValue: 0); // 0 = Green

            migrationBuilder.AddColumn<string>(
                name: "ChiefComplaint",
                table: "WaitingLists",
                type: "TEXT",
                nullable: true);

            // Criar índice para demandas espontâneas
            migrationBuilder.CreateIndex(
                name: "IX_WaitingLists_IsSpontaneousDemand",
                table: "WaitingLists",
                column: "IsSpontaneousDemand");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Remover índice
            migrationBuilder.DropIndex(
                name: "IX_WaitingLists_IsSpontaneousDemand",
                table: "WaitingLists");

            // Remover colunas
            migrationBuilder.DropColumn(
                name: "IsSpontaneousDemand",
                table: "WaitingLists");

            migrationBuilder.DropColumn(
                name: "UrgencyLevel",
                table: "WaitingLists");

            migrationBuilder.DropColumn(
                name: "ChiefComplaint",
                table: "WaitingLists");
        }
    }
}
