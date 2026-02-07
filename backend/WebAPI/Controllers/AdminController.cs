using Application.DTOs.Reference;
using Application.Interfaces;
using Domain.Entities;
using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using System.Security.Claims;
using CsvHelper;
using CsvHelper.Configuration;

namespace WebAPI.Controllers;

/// <summary>
/// Controller de administração para importação de tabelas de referência
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "ADMIN")]
public class AdminController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IAuditLogService _auditLogService;

    public AdminController(ApplicationDbContext context, IAuditLogService auditLogService)
    {
        _context = context;
        _auditLogService = auditLogService;
    }

    private Guid? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return userIdClaim != null ? Guid.Parse(userIdClaim) : null;
    }

    #region Conselhos Profissionais

    /// <summary>
    /// Lista todos os conselhos profissionais
    /// </summary>
    [HttpGet("councils")]
    public async Task<ActionResult<List<ProfessionalCouncilDto>>> GetCouncils()
    {
        var councils = await _context.ProfessionalCouncils
            .Where(c => c.IsActive)
            .OrderBy(c => c.Acronym)
            .Select(c => new ProfessionalCouncilDto
            {
                Id = c.Id,
                Acronym = c.Acronym,
                Name = c.Name,
                Category = c.Category
            })
            .ToListAsync();

        return Ok(councils);
    }

    #endregion

    #region CBO - Classificação Brasileira de Ocupações

    /// <summary>
    /// Lista ocupações CBO
    /// </summary>
    [HttpGet("cbo")]
    [AllowAnonymous]
    public async Task<ActionResult<List<CboOccupationDto>>> GetCboOccupations(
        [FromQuery] string? search = null,
        [FromQuery] bool? teleconsultation = null)
    {
        var query = _context.CboOccupations
            .Where(c => c.IsActive)
            .AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(c => c.Code.ToLower().Contains(searchLower) ||
                                    c.Name.ToLower().Contains(searchLower));
        }

        if (teleconsultation.HasValue)
        {
            query = query.Where(c => c.AllowsTeleconsultation == teleconsultation.Value);
        }

        var occupations = await query
            .OrderBy(c => c.Code)
            .Take(100)
            .Select(c => new CboOccupationDto
            {
                Id = c.Id,
                Code = c.Code,
                Name = c.Name,
                Family = c.Family,
                Subgroup = c.Subgroup,
                AllowsTeleconsultation = c.AllowsTeleconsultation
            })
            .ToListAsync();

        return Ok(occupations);
    }

    /// <summary>
    /// Importa ocupações CBO de arquivo CSV
    /// Formato esperado: Código;Nome;Família;Subgrupo;PermiteTeleconsulta
    /// </summary>
    [HttpPost("import/cbo")]
    public async Task<ActionResult<ImportResultDto>> ImportCbo(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Arquivo não fornecido" });

        var userId = GetCurrentUserId();
        if (userId == null)
            return Unauthorized();

        var result = new ImportResultDto();

        try
        {
            using var reader = new StreamReader(file.OpenReadStream());
            using var csv = new CsvReader(reader, new CsvConfiguration(CultureInfo.GetCultureInfo("pt-BR"))
            {
                Delimiter = ";",
                HasHeaderRecord = true,
                MissingFieldFound = null,
                HeaderValidated = null
            });

            var records = csv.GetRecords<CboImportDto>().ToList();

            foreach (var record in records)
            {
                result.TotalRecords++;

                if (string.IsNullOrEmpty(record.Code) || string.IsNullOrEmpty(record.Name))
                {
                    result.Errors.Add($"Registro inválido: código ou nome vazio");
                    continue;
                }

                var existing = await _context.CboOccupations
                    .FirstOrDefaultAsync(c => c.Code == record.Code);

                if (existing != null)
                {
                    // Atualiza registro existente
                    existing.Name = record.Name;
                    existing.Family = record.Family;
                    existing.Subgroup = record.Subgroup;
                    existing.AllowsTeleconsultation = record.AllowsTeleconsultation;
                    existing.UpdatedAt = DateTime.UtcNow;
                    result.UpdatedRecords++;
                }
                else
                {
                    // Insere novo registro
                    var occupation = new CboOccupation
                    {
                        Code = record.Code,
                        Name = record.Name,
                        Family = record.Family,
                        Subgroup = record.Subgroup,
                        AllowsTeleconsultation = record.AllowsTeleconsultation
                    };
                    _context.CboOccupations.Add(occupation);
                    result.InsertedRecords++;
                }
            }

            await _context.SaveChangesAsync();
            result.Success = true;
            result.Message = $"Importação concluída: {result.InsertedRecords} inseridos, {result.UpdatedRecords} atualizados";

            // Registra auditoria
            await _auditLogService.LogAsync(
                userId.Value,
                "IMPORT_CBO",
                "CboOccupation",
                "BATCH",
                null,
                $"Total: {result.TotalRecords}, Inseridos: {result.InsertedRecords}, Atualizados: {result.UpdatedRecords}",
                HttpContext.Connection.RemoteIpAddress?.ToString(),
                Request.Headers["User-Agent"].ToString(),
                dataCategory: "CONFIGURACAO",
                accessReason: "Importação de tabela CBO"
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Message = $"Erro na importação: {ex.Message}";
            return StatusCode(500, result);
        }
    }

    #endregion

    #region SIGTAP - Sistema de Gerenciamento da Tabela de Procedimentos

    /// <summary>
    /// Lista procedimentos SIGTAP
    /// </summary>
    [HttpGet("sigtap")]
    [AllowAnonymous]
    public async Task<ActionResult<List<SigtapProcedureDto>>> GetSigtapProcedures(
        [FromQuery] string? search = null,
        [FromQuery] bool? telemedicine = null)
    {
        var query = _context.SigtapProcedures
            .Where(s => s.IsActive)
            .AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(s => s.Code.ToLower().Contains(searchLower) ||
                                    s.Name.ToLower().Contains(searchLower));
        }

        if (telemedicine.HasValue)
        {
            query = query.Where(s => s.AllowsTelemedicine == telemedicine.Value);
        }

        var procedures = await query
            .OrderBy(s => s.Code)
            .Take(100)
            .Select(s => new SigtapProcedureDto
            {
                Id = s.Id,
                Code = s.Code,
                Name = s.Name,
                Description = s.Description,
                Complexity = s.Complexity.ToString(),
                GroupCode = s.GroupCode,
                GroupName = s.GroupName,
                SubgroupCode = s.SubgroupCode,
                SubgroupName = s.SubgroupName,
                Value = s.Value,
                AllowsTelemedicine = s.AllowsTelemedicine
            })
            .ToListAsync();

        return Ok(procedures);
    }

    /// <summary>
    /// Importa procedimentos SIGTAP de arquivo CSV
    /// Formato esperado: Código;Nome;Descrição;Complexidade;CódGrupo;NomeGrupo;CódSubgrupo;NomeSubgrupo;Valor;PermiteTelemedicina
    /// </summary>
    [HttpPost("import/sigtap")]
    public async Task<ActionResult<ImportResultDto>> ImportSigtap(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Arquivo não fornecido" });

        var userId = GetCurrentUserId();
        if (userId == null)
            return Unauthorized();

        var result = new ImportResultDto();

        try
        {
            using var reader = new StreamReader(file.OpenReadStream());
            using var csv = new CsvReader(reader, new CsvConfiguration(CultureInfo.GetCultureInfo("pt-BR"))
            {
                Delimiter = ";",
                HasHeaderRecord = true,
                MissingFieldFound = null,
                HeaderValidated = null
            });

            var records = csv.GetRecords<SigtapImportDto>().ToList();

            foreach (var record in records)
            {
                result.TotalRecords++;

                if (string.IsNullOrEmpty(record.Code) || string.IsNullOrEmpty(record.Name))
                {
                    result.Errors.Add($"Registro inválido: código ou nome vazio");
                    continue;
                }

                var existing = await _context.SigtapProcedures
                    .FirstOrDefaultAsync(s => s.Code == record.Code);

                if (existing != null)
                {
                    // Atualiza registro existente
                    existing.Name = record.Name;
                    existing.Description = record.Description;
                    existing.Complexity = ParseComplexity(record.Complexity);
                    existing.GroupCode = record.GroupCode;
                    existing.GroupName = record.GroupName;
                    existing.SubgroupCode = record.SubgroupCode;
                    existing.SubgroupName = record.SubgroupName;
                    existing.Value = record.Value;
                    existing.AllowsTelemedicine = record.AllowsTelemedicine;
                    existing.UpdatedAt = DateTime.UtcNow;
                    result.UpdatedRecords++;
                }
                else
                {
                    // Insere novo registro
                    var procedure = new SigtapProcedure
                    {
                        Code = record.Code,
                        Name = record.Name,
                        Description = record.Description,
                        Complexity = ParseComplexity(record.Complexity),
                        GroupCode = record.GroupCode,
                        GroupName = record.GroupName,
                        SubgroupCode = record.SubgroupCode,
                        SubgroupName = record.SubgroupName,
                        Value = record.Value,
                        AllowsTelemedicine = record.AllowsTelemedicine
                    };
                    _context.SigtapProcedures.Add(procedure);
                    result.InsertedRecords++;
                }
            }

            await _context.SaveChangesAsync();
            result.Success = true;
            result.Message = $"Importação concluída: {result.InsertedRecords} inseridos, {result.UpdatedRecords} atualizados";

            // Registra auditoria
            await _auditLogService.LogAsync(
                userId.Value,
                "IMPORT_SIGTAP",
                "SigtapProcedure",
                "BATCH",
                null,
                $"Total: {result.TotalRecords}, Inseridos: {result.InsertedRecords}, Atualizados: {result.UpdatedRecords}",
                HttpContext.Connection.RemoteIpAddress?.ToString(),
                Request.Headers["User-Agent"].ToString(),
                dataCategory: "CONFIGURACAO",
                accessReason: "Importação de tabela SIGTAP"
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Message = $"Erro na importação: {ex.Message}";
            return StatusCode(500, result);
        }
    }

    #endregion

    #region Exportação de Auditoria

    /// <summary>
    /// Exporta logs de auditoria em CSV
    /// </summary>
    [HttpGet("audit/export")]
    public async Task<IActionResult> ExportAuditLogs(
        [FromQuery] Guid? userId = null,
        [FromQuery] Guid? patientId = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        var currentUserId = GetCurrentUserId();
        if (currentUserId == null)
            return Unauthorized();

        var csvBytes = await _auditLogService.ExportAuditLogsCsvAsync(userId, patientId, startDate, endDate);

        // Registra a exportação
        await _auditLogService.LogAsync(
            currentUserId.Value,
            "EXPORT_AUDIT_LOGS",
            "AuditLog",
            "EXPORT",
            null,
            $"Filtros: userId={userId}, patientId={patientId}, startDate={startDate}, endDate={endDate}",
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            Request.Headers["User-Agent"].ToString(),
            patientId: patientId,
            dataCategory: "AUDITORIA",
            accessReason: "Exportação de logs de auditoria"
        );

        var fileName = $"auditoria_{DateTime.Now:yyyyMMdd_HHmmss}.csv";
        return File(csvBytes, "text/csv; charset=utf-8", fileName);
    }

    /// <summary>
    /// Busca logs de auditoria por paciente
    /// </summary>
    [HttpGet("audit/patient/{patientId}")]
    public async Task<ActionResult> GetAuditByPatient(
        Guid patientId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        var currentUserId = GetCurrentUserId();
        if (currentUserId == null)
            return Unauthorized();

        var result = await _auditLogService.GetAuditLogsByPatientAsync(patientId, page, pageSize, startDate, endDate);

        // Registra a consulta
        await _auditLogService.LogAsync(
            currentUserId.Value,
            "VIEW_PATIENT_AUDIT",
            "AuditLog",
            patientId.ToString(),
            null,
            null,
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            Request.Headers["User-Agent"].ToString(),
            patientId: patientId,
            dataCategory: "AUDITORIA",
            accessReason: "Consulta de logs de auditoria do paciente"
        );

        return Ok(result);
    }

    #endregion

    #region Helpers

    private static ProcedureComplexity ParseComplexity(string? complexity)
    {
        if (string.IsNullOrEmpty(complexity))
            return ProcedureComplexity.Basic;

        return complexity.ToLower() switch
        {
            "basic" or "basica" or "básica" or "ab" => ProcedureComplexity.Basic,
            "medium" or "media" or "média" or "mc" => ProcedureComplexity.Medium,
            "high" or "alta" or "ac" => ProcedureComplexity.High,
            _ => ProcedureComplexity.Basic
        };
    }

    #endregion

    #region Gestão de Reguladores

    /// <summary>
    /// Lista todos os reguladores com informações de município vinculado
    /// </summary>
    [HttpGet("regulators")]
    public async Task<ActionResult> GetRegulators()
    {
        var regulators = await _context.Users
            .Include(u => u.Municipio)
            .Where(u => u.Role == Domain.Enums.UserRole.REGULATOR)
            .OrderBy(u => u.Name)
            .Select(u => new
            {
                id = u.Id,
                name = u.Name,
                lastName = u.LastName,
                fullName = u.Name + " " + u.LastName,
                email = u.Email,
                cpf = u.Cpf,
                phone = u.Phone,
                status = u.Status.ToString(),
                municipioId = u.MunicipioId,
                municipio = u.Municipio != null ? new
                {
                    id = u.Municipio.Id,
                    nome = u.Municipio.Nome,
                    uf = u.Municipio.UF,
                    codigoIbge = u.Municipio.CodigoIBGE
                } : null,
                createdAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(regulators);
    }

    /// <summary>
    /// Vincula um regulador a um município
    /// </summary>
    [HttpPost("regulators/{regulatorId}/vinculate")]
    public async Task<ActionResult> VinculateRegulatorToMunicipality(
        Guid regulatorId, 
        [FromBody] VinculateRegulatorDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
            return Unauthorized();

        var regulator = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == regulatorId && u.Role == Domain.Enums.UserRole.REGULATOR);

        if (regulator == null)
            return NotFound(new { message = "Regulador não encontrado" });

        // Validar município se foi informado
        if (dto.MunicipioId.HasValue)
        {
            var municipio = await _context.Municipalities
                .FirstOrDefaultAsync(m => m.Id == dto.MunicipioId.Value);

            if (municipio == null)
                return BadRequest(new { message = "Município não encontrado" });

            // Verificar se outro regulador já está vinculado a este município
            var existingRegulator = await _context.Users
                .FirstOrDefaultAsync(u => u.MunicipioId == dto.MunicipioId.Value && 
                                         u.Role == Domain.Enums.UserRole.REGULATOR &&
                                         u.Id != regulatorId);

            if (existingRegulator != null)
                return BadRequest(new { message = $"O município já possui um regulador vinculado: {existingRegulator.Name} {existingRegulator.LastName}" });
        }

        var oldMunicipioId = regulator.MunicipioId;
        regulator.MunicipioId = dto.MunicipioId;
        regulator.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Registrar auditoria
        await _auditLogService.LogAsync(
            userId.Value,
            "UPDATE",
            "User",
            regulatorId.ToString(),
            System.Text.Json.JsonSerializer.Serialize(new { oldMunicipioId }),
            System.Text.Json.JsonSerializer.Serialize(new { newMunicipioId = dto.MunicipioId }),
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            Request.Headers["User-Agent"].ToString(),
            dataCategory: "ADMINISTRAÇÃO",
            accessReason: "Vinculação de regulador a município"
        );

        // Retornar dados atualizados
        var municipioInfo = dto.MunicipioId.HasValue
            ? await _context.Municipalities
                .Where(m => m.Id == dto.MunicipioId.Value)
                .Select(m => new { id = m.Id, nome = m.Nome, uf = m.UF })
                .FirstOrDefaultAsync()
            : null;

        return Ok(new
        {
            message = dto.MunicipioId.HasValue 
                ? "Regulador vinculado ao município com sucesso" 
                : "Vínculo do regulador removido com sucesso",
            regulatorId,
            municipio = municipioInfo
        });
    }

    /// <summary>
    /// Cria um novo usuário regulador
    /// </summary>
    [HttpPost("regulators")]
    public async Task<ActionResult> CreateRegulator([FromBody] CreateRegulatorDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
            return Unauthorized();

        // Validar email único
        var existingEmail = await _context.Users
            .AnyAsync(u => u.Email.ToLower() == dto.Email.ToLower());

        if (existingEmail)
            return BadRequest(new { message = "Email já cadastrado no sistema" });

        // Validar CPF único
        var existingCpf = await _context.Users
            .AnyAsync(u => u.Cpf == dto.Cpf);

        if (existingCpf)
            return BadRequest(new { message = "CPF já cadastrado no sistema" });

        // Validar município se informado
        if (dto.MunicipioId.HasValue)
        {
            var municipioExists = await _context.Municipalities
                .AnyAsync(m => m.Id == dto.MunicipioId.Value);

            if (!municipioExists)
                return BadRequest(new { message = "Município não encontrado" });
        }

        var regulator = new User
        {
            Id = Guid.NewGuid(),
            Name = dto.Name,
            LastName = dto.LastName,
            Email = dto.Email.ToLower(),
            Cpf = dto.Cpf,
            Phone = dto.Phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Role = Domain.Enums.UserRole.REGULATOR,
            Status = Domain.Enums.UserStatus.Active,
            EmailVerified = true, // Admin cria já verificado
            MunicipioId = dto.MunicipioId,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Users.Add(regulator);
        await _context.SaveChangesAsync();

        // Registrar auditoria
        await _auditLogService.LogAsync(
            userId.Value,
            "CREATE",
            "User",
            regulator.Id.ToString(),
            null,
            System.Text.Json.JsonSerializer.Serialize(new { email = regulator.Email, role = "REGULATOR", municipioId = regulator.MunicipioId }),
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            Request.Headers["User-Agent"].ToString(),
            dataCategory: "ADMINISTRAÇÃO",
            accessReason: "Criação de regulador"
        );

        return Ok(new
        {
            message = "Regulador criado com sucesso",
            id = regulator.Id,
            email = regulator.Email
        });
    }

    /// <summary>
    /// Lista municípios disponíveis para vinculação (sem regulador ou todos)
    /// </summary>
    [HttpGet("municipalities/available")]
    public async Task<ActionResult> GetAvailableMunicipalities([FromQuery] bool onlyAvailable = false)
    {
        var query = _context.Municipalities.AsQueryable();

        if (onlyAvailable)
        {
            // Pegar IDs de municípios que já têm regulador
            var municipiosComRegulador = await _context.Users
                .Where(u => u.Role == Domain.Enums.UserRole.REGULATOR && u.MunicipioId.HasValue)
                .Select(u => u.MunicipioId!.Value)
                .ToListAsync();

            query = query.Where(m => !municipiosComRegulador.Contains(m.Id));
        }

        var municipalities = await query
            .OrderBy(m => m.Nome)
            .Select(m => new
            {
                id = m.Id,
                nome = m.Nome,
                uf = m.UF,
                codigoIbge = m.CodigoIBGE,
                temRegulador = _context.Users.Any(u => u.MunicipioId == m.Id && u.Role == Domain.Enums.UserRole.REGULATOR)
            })
            .ToListAsync();

        return Ok(municipalities);
    }

    #endregion
}

/// <summary>
/// DTO para vincular regulador a município
/// </summary>
public class VinculateRegulatorDto
{
    /// <summary>
    /// ID do município. Null para remover vínculo.
    /// </summary>
    public Guid? MunicipioId { get; set; }
}

/// <summary>
/// DTO para criar novo regulador
/// </summary>
public class CreateRegulatorDto
{
    public string Name { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Cpf { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Password { get; set; } = string.Empty;
    public Guid? MunicipioId { get; set; }
}
