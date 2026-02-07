using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Domain.Entities;
using Domain.Enums;

namespace WebAPI.Controllers;

/// <summary>
/// Controller para funcionalidades do Regulador Municipal
/// Acesso restrito a usuários com Role = REGULATOR
/// Todos os dados são filtrados pelo município vinculado ao regulador
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "REGULATOR")]
public class RegulatorController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<RegulatorController> _logger;

    public RegulatorController(
        ApplicationDbContext context,
        ILogger<RegulatorController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private Guid? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return userIdClaim != null ? Guid.Parse(userIdClaim) : null;
    }

    /// <summary>
    /// Obtém o município vinculado ao regulador logado - OTIMIZADO com projeção
    /// </summary>
    private async Task<Guid?> GetRegulatorMunicipioIdAsync()
    {
        var userId = GetCurrentUserId();
        if (userId == null) return null;

        // Projeção otimizada - busca apenas MunicipioId
        return await _context.Users
            .AsNoTracking()
            .Where(u => u.Id == userId)
            .Select(u => u.MunicipioId)
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Estatísticas do município para o dashboard do regulador
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        var hoje = DateTime.Today;

        // OTIMIZAÇÃO: Queries em paralelo (Task.WhenAll)
        var totalPacientesTask = _context.PatientProfiles
            .AsNoTracking()
            .Where(pp => pp.MunicipioId == municipioId)
            .CountAsync();

        var consultasHojeTask = _context.Appointments
            .AsNoTracking()
            .Where(a => a.Date.Date == hoje &&
                       a.Patient.PatientProfile != null &&
                       a.Patient.PatientProfile.MunicipioId == municipioId)
            .CountAsync();

        var consultasPendentesTask = _context.Appointments
            .AsNoTracking()
            .Where(a => a.Date.Date >= hoje &&
                       (a.Status == AppointmentStatus.Scheduled || a.Status == AppointmentStatus.Confirmed) &&
                       a.Patient.PatientProfile != null &&
                       a.Patient.PatientProfile.MunicipioId == municipioId)
            .CountAsync();

        var agendasDisponiveisTask = _context.Schedules
            .AsNoTracking()
            .Where(s => s.IsActive)
            .CountAsync();

        // Executar todas as queries em paralelo
        await Task.WhenAll(totalPacientesTask, consultasHojeTask, consultasPendentesTask, agendasDisponiveisTask);

        var totalPacientes = await totalPacientesTask;
        var consultasHoje = await consultasHojeTask;
        var consultasPendentes = await consultasPendentesTask;
        var agendasDisponiveis = await agendasDisponiveisTask;

        // Info do município
        var municipio = await _context.Municipalities
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Id == municipioId);

        return Ok(new
        {
            totalPacientes,
            consultasHoje,
            consultasPendentes,
            agendasDisponiveis,
            municipio = municipio != null ? new
            {
                id = municipio.Id,
                nome = municipio.Nome,
                uf = municipio.UF,
                codigoIbge = municipio.CodigoIBGE
            } : null
        });
    }

    /// <summary>
    /// Lista pacientes do município com paginação e filtros
    /// </summary>
    [HttpGet("patients")]
    public async Task<IActionResult> GetPatients(
        [FromQuery] string? search = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        // OTIMIZAÇÃO: Começar pelo PatientProfile (tem índice no MunicipioId)
        var query = _context.PatientProfiles
            .AsNoTracking()
            .Where(pp => pp.MunicipioId == municipioId)
            .Select(pp => pp.User);

        // Filtro de busca
        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchLower = search.ToLower();
            query = query.Where(u => 
                u.Name.ToLower().Contains(searchLower) ||
                u.LastName.ToLower().Contains(searchLower) ||
                u.Cpf.Contains(search) ||
                u.Email.ToLower().Contains(searchLower) ||
                (u.PatientProfile!.Cns != null && u.PatientProfile.Cns.Contains(search)));
        }

        var total = await query.CountAsync();

        var patients = await query
            .OrderBy(u => u.Name)
            .ThenBy(u => u.LastName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new
            {
                id = u.Id,
                name = u.Name,
                lastName = u.LastName,
                fullName = u.Name + " " + u.LastName,
                email = u.Email,
                cpf = u.Cpf,
                phone = u.Phone,
                avatar = u.Avatar,
                status = u.Status.ToString(),
                cns = u.PatientProfile!.Cns,
                birthDate = u.PatientProfile.BirthDate,
                gender = u.PatientProfile.Gender,
                city = u.PatientProfile.City,
                state = u.PatientProfile.State,
                createdAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(new
        {
            data = patients,
            pagination = new
            {
                page,
                pageSize,
                total,
                totalPages = (int)Math.Ceiling((double)total / pageSize)
            }
        });
    }

    /// <summary>
    /// Detalhes de um paciente específico
    /// </summary>
    [HttpGet("patients/{patientId}")]
    public async Task<IActionResult> GetPatientDetails(Guid patientId)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        var patient = await _context.Users
            .Include(u => u.PatientProfile)
            .Where(u => u.Id == patientId && 
                       u.Role == UserRole.PATIENT && 
                       u.PatientProfile != null && 
                       u.PatientProfile.MunicipioId == municipioId)
            .Select(u => new
            {
                id = u.Id,
                name = u.Name,
                lastName = u.LastName,
                email = u.Email,
                cpf = u.Cpf,
                phone = u.Phone,
                avatar = u.Avatar,
                status = u.Status.ToString(),
                profile = new
                {
                    cns = u.PatientProfile!.Cns,
                    socialName = u.PatientProfile.SocialName,
                    birthDate = u.PatientProfile.BirthDate,
                    gender = u.PatientProfile.Gender,
                    motherName = u.PatientProfile.MotherName,
                    nationalidade = u.PatientProfile.Nationality,
                    racaCor = u.PatientProfile.RacaCor,
                    zipCode = u.PatientProfile.ZipCode,
                    logradouro = u.PatientProfile.Logradouro,
                    numero = u.PatientProfile.Numero,
                    complemento = u.PatientProfile.Complemento,
                    bairro = u.PatientProfile.Bairro,
                    city = u.PatientProfile.City,
                    state = u.PatientProfile.State
                },
                createdAt = u.CreatedAt
            })
            .FirstOrDefaultAsync();

        if (patient == null)
            return NotFound(new { message = "Paciente não encontrado ou não pertence ao seu município" });

        // Buscar histórico de consultas
        var appointments = await _context.Appointments
            .Include(a => a.Professional)
            .Include(a => a.Specialty)
            .Where(a => a.PatientId == patientId)
            .OrderByDescending(a => a.Date)
            .ThenByDescending(a => a.Time)
            .Take(10)
            .Select(a => new
            {
                id = a.Id,
                date = a.Date,
                time = a.Time,
                status = a.Status.ToString(),
                professionalName = a.Professional.Name + " " + a.Professional.LastName,
                specialtyName = a.Specialty.Name
            })
            .ToListAsync();

        return Ok(new
        {
            patient,
            recentAppointments = appointments
        });
    }

    /// <summary>
    /// Lista consultas do município com filtros - OTIMIZADO
    /// </summary>
    [HttpGet("appointments")]
    public async Task<IActionResult> GetAppointments(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? status = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        // OTIMIZAÇÃO: Sem Include, apenas projeção
        var query = _context.Appointments
            .AsNoTracking()
            .Where(a => a.Patient.PatientProfile != null &&
                       a.Patient.PatientProfile.MunicipioId == municipioId);

        // Filtro de data
        if (startDate.HasValue)
            query = query.Where(a => a.Date >= startDate.Value.Date);
        
        if (endDate.HasValue)
            query = query.Where(a => a.Date <= endDate.Value.Date);

        // Filtro de status
        if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<AppointmentStatus>(status, true, out var statusEnum))
            query = query.Where(a => a.Status == statusEnum);

        var total = await query.CountAsync();

        var appointments = await query
            .OrderByDescending(a => a.Date)
            .ThenByDescending(a => a.Time)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new
            {
                id = a.Id,
                date = a.Date,
                time = a.Time,
                status = a.Status.ToString(),
                patient = new
                {
                    id = a.Patient.Id,
                    name = a.Patient.Name + " " + a.Patient.LastName,
                    cpf = a.Patient.Cpf
                },
                professional = new
                {
                    id = a.Professional.Id,
                    name = a.Professional.Name + " " + a.Professional.LastName
                },
                specialty = new
                {
                    id = a.Specialty.Id,
                    name = a.Specialty.Name
                }
            })
            .ToListAsync();

        return Ok(new
        {
            data = appointments,
            pagination = new
            {
                page,
                pageSize,
                total,
                totalPages = (int)Math.Ceiling((double)total / pageSize)
            }
        });
    }

    /// <summary>
    /// Lista agendas ativas dos profissionais - OTIMIZADO sem Include
    /// </summary>
    [HttpGet("available-schedules")]
    public async Task<IActionResult> GetAvailableSchedules()
    {
        // OTIMIZAÇÃO: Projeção direta sem Include aninhados
        var schedules = await _context.Schedules
            .AsNoTracking()
            .Where(s => s.IsActive)
            .Select(s => new
            {
                id = s.Id,
                validityStartDate = s.ValidityStartDate,
                validityEndDate = s.ValidityEndDate,
                isActive = s.IsActive,
                professional = new
                {
                    id = s.Professional.Id,
                    name = s.Professional.Name + " " + s.Professional.LastName,
                    specialty = s.Professional.ProfessionalProfile != null && s.Professional.ProfessionalProfile.Specialty != null 
                        ? s.Professional.ProfessionalProfile.Specialty.Name 
                        : "Não definida"
                }
            })
            .OrderBy(s => s.professional.name)
            .ToListAsync();

        return Ok(schedules);
    }

    /// <summary>
    /// Lista especialidades disponíveis no sistema
    /// </summary>
    [HttpGet("specialties")]
    public async Task<IActionResult> GetSpecialties()
    {
        var specialties = await _context.Specialties
            .Where(s => s.Status == SpecialtyStatus.Active)
            .OrderBy(s => s.Name)
            .Select(s => new
            {
                id = s.Id,
                name = s.Name,
                description = s.Description
            })
            .ToListAsync();

        return Ok(specialties);
    }
}
