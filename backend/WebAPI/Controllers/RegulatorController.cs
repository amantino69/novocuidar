using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Domain.Entities;
using Domain.Enums;
using Application.Interfaces;
using Application.DTOs.Schedules;

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
    private readonly ICnsService _cnsService;

    public RegulatorController(
        ApplicationDbContext context,
        ILogger<RegulatorController> logger,
        ICnsService cnsService)
    {
        _context = context;
        _logger = logger;
        _cnsService = cnsService;
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
    /// OTIMIZADO: Queries simplificadas com subquery em vez de joins múltiplos
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        var hoje = DateTime.Today;

        // OTIMIZAÇÃO: Obter IDs dos pacientes do município uma vez
        var patientIds = _context.PatientProfiles
            .AsNoTracking()
            .Where(pp => pp.MunicipioId == municipioId)
            .Select(pp => pp.UserId);

        // OTIMIZAÇÃO: Queries paralelas usando subquery
        var totalPacientesTask = patientIds.CountAsync();

        var consultasHojeTask = _context.Appointments
            .AsNoTracking()
            .Where(a => a.Date.Date == hoje && patientIds.Contains(a.PatientId))
            .CountAsync();

        var consultasPendentesTask = _context.Appointments
            .AsNoTracking()
            .Where(a => a.Date.Date >= hoje &&
                       (a.Status == AppointmentStatus.Scheduled || a.Status == AppointmentStatus.Confirmed) &&
                       patientIds.Contains(a.PatientId))
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
    /// OTIMIZADO: Usa ILike para busca case-insensitive nativa do PostgreSQL
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

        // OTIMIZAÇÃO: Query simplificada com projeção direta
        // Primeiro pegar IDs dos pacientes do município
        var patientIdsQuery = _context.PatientProfiles
            .AsNoTracking()
            .Where(pp => pp.MunicipioId == municipioId)
            .Select(pp => pp.UserId);

        // Depois buscar usuários
        var query = _context.Users
            .AsNoTracking()
            .Where(u => patientIdsQuery.Contains(u.Id));

        // Filtro de busca otimizado (case-insensitive nativo PostgreSQL)
        if (!string.IsNullOrWhiteSpace(search))
        {
            var searchPattern = $"%{search}%";
            query = query.Where(u => 
                EF.Functions.ILike(u.Name, searchPattern) ||
                EF.Functions.ILike(u.LastName, searchPattern) ||
                u.Cpf.Contains(search) ||
                EF.Functions.ILike(u.Email, searchPattern));
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
                .ThenInclude(pp => pp!.UnidadeAdscrita)
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
                    fatherName = u.PatientProfile.FatherName,
                    nationality = u.PatientProfile.Nationality,
                    racaCor = u.PatientProfile.RacaCor,
                    zipCode = u.PatientProfile.ZipCode,
                    logradouro = u.PatientProfile.Logradouro,
                    numero = u.PatientProfile.Numero,
                    complemento = u.PatientProfile.Complemento,
                    bairro = u.PatientProfile.Bairro,
                    city = u.PatientProfile.City,
                    state = u.PatientProfile.State,
                    unidadeAdscritaId = u.PatientProfile.UnidadeAdscritaId,
                    unidadeAdscritaNome = u.PatientProfile.UnidadeAdscrita != null ? u.PatientProfile.UnidadeAdscrita.NomeFantasia : null,
                    // Campos do responsável legal
                    responsavelNome = u.PatientProfile.ResponsavelNome,
                    responsavelCpf = u.PatientProfile.ResponsavelCpf,
                    responsavelTelefone = u.PatientProfile.ResponsavelTelefone,
                    responsavelEmail = u.PatientProfile.ResponsavelEmail,
                    responsavelGrauParentesco = u.PatientProfile.ResponsavelGrauParentesco
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
    /// Usa subquery em vez de joins para melhor performance
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

        // OTIMIZAÇÃO: Obter IDs dos pacientes do município uma vez
        var patientIds = _context.PatientProfiles
            .AsNoTracking()
            .Where(pp => pp.MunicipioId == municipioId)
            .Select(pp => pp.UserId);

        // Query principal usando subquery
        var query = _context.Appointments
            .AsNoTracking()
            .Where(a => patientIds.Contains(a.PatientId));

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
                        : "Não definida",
                    specialtyId = s.Professional.ProfessionalProfile != null && s.Professional.ProfessionalProfile.SpecialtyId != null 
                        ? s.Professional.ProfessionalProfile.SpecialtyId 
                        : (Guid?)null
                }
            })
            .OrderBy(s => s.professional.name)
            .ToListAsync();

        return Ok(schedules);
    }

    /// <summary>
    /// Busca horários disponíveis para uma agenda específica
    /// Retorna slots disponíveis nos próximos 30 dias
    /// </summary>
    [HttpGet("available-schedules/{scheduleId}/slots")]
    public async Task<IActionResult> GetScheduleSlots(Guid scheduleId, [FromQuery] DateTime? startDate = null, [FromQuery] DateTime? endDate = null)
    {
        var schedule = await _context.Schedules
            .Include(s => s.Professional)
                .ThenInclude(p => p.ProfessionalProfile)
                    .ThenInclude(pp => pp!.Specialty)
            .FirstOrDefaultAsync(s => s.Id == scheduleId && s.IsActive);

        if (schedule == null)
            return NotFound(new { message = "Agenda não encontrada ou inativa" });

        // Período de busca (padrão: próximos 30 dias)
        var dataInicio = startDate ?? DateTime.Today;
        var dataFim = endDate ?? DateTime.Today.AddDays(30);

        // Não permitir datas no passado
        if (dataInicio < DateTime.Today)
            dataInicio = DateTime.Today;

        // Limitar a 60 dias
        if ((dataFim - dataInicio).TotalDays > 60)
            dataFim = dataInicio.AddDays(60);

        // Parse da configuração dos dias do JSON
        var daysConfig = new List<DayConfigDto>();
        var globalConfig = new GlobalConfigDto();
        
        try
        {
            if (!string.IsNullOrEmpty(schedule.DaysConfigJson))
                daysConfig = System.Text.Json.JsonSerializer.Deserialize<List<DayConfigDto>>(schedule.DaysConfigJson) ?? new List<DayConfigDto>();
            if (!string.IsNullOrEmpty(schedule.GlobalConfigJson))
                globalConfig = System.Text.Json.JsonSerializer.Deserialize<GlobalConfigDto>(schedule.GlobalConfigJson) ?? new GlobalConfigDto();
        }
        catch (Exception ex)
        {
            _logger.LogWarning("Erro ao deserializar configuração da agenda {ScheduleId}: {Error}", scheduleId, ex.Message);
        }

        // Duração do slot a partir da configuração global
        var slotDuration = globalConfig.ConsultationDuration > 0 ? globalConfig.ConsultationDuration : 30;

        // Buscar consultas já agendadas no período
        var consultasAgendadas = await _context.Appointments
            .AsNoTracking()
            .Where(a => a.ProfessionalId == schedule.ProfessionalId &&
                       a.Date >= dataInicio && a.Date <= dataFim &&
                       (a.Status == AppointmentStatus.Scheduled || a.Status == AppointmentStatus.Confirmed))
            .Select(a => new { a.Date, a.Time })
            .ToListAsync();

        var slotsDisponiveis = new List<object>();

        // Gerar slots para cada dia no período
        for (var data = dataInicio; data <= dataFim; data = data.AddDays(1))
        {
            var diaSemana = data.DayOfWeek;
            var dayName = diaSemana.ToString();
            var configDia = daysConfig.FirstOrDefault(d => d.Day == dayName && d.IsWorking);

            if (configDia == null) continue;

            // Usar horários específicos do dia ou da configuração global
            var startTimeStr = configDia.TimeRange?.StartTime ?? globalConfig.TimeRange?.StartTime ?? "08:00";
            var endTimeStr = configDia.TimeRange?.EndTime ?? globalConfig.TimeRange?.EndTime ?? "18:00";

            if (!TimeSpan.TryParse(startTimeStr, out var horaInicio) || 
                !TimeSpan.TryParse(endTimeStr, out var horaFim))
                continue;

            // Gerar horários do dia
            var horaAtual = horaInicio;
            while (horaAtual < horaFim)
            {
                var horarioStr = horaAtual.ToString(@"hh\:mm");

                // Verificar se não está ocupado (comparando TimeSpan)
                var ocupado = consultasAgendadas.Any(c => c.Date.Date == data.Date && c.Time == horaAtual);

                // Não mostrar horários passados para hoje
                if (data.Date == DateTime.Today.Date)
                {
                    var agora = DateTime.Now.TimeOfDay;
                    if (horaAtual <= agora)
                    {
                        horaAtual = horaAtual.Add(TimeSpan.FromMinutes(slotDuration));
                        continue;
                    }
                }

                if (!ocupado)
                {
                    slotsDisponiveis.Add(new
                    {
                        date = data.ToString("yyyy-MM-dd"),
                        time = horarioStr,
                        dayOfWeek = dayName,
                        dayOfWeekPt = GetDayOfWeekPt(diaSemana)
                    });
                }

                horaAtual = horaAtual.Add(TimeSpan.FromMinutes(slotDuration));
            }
        }

        return Ok(new
        {
            schedule = new
            {
                id = schedule.Id,
                professional = new
                {
                    id = schedule.Professional.Id,
                    name = schedule.Professional.Name + " " + schedule.Professional.LastName,
                    specialty = schedule.Professional.ProfessionalProfile?.Specialty?.Name ?? "Não definida",
                    specialtyId = schedule.Professional.ProfessionalProfile?.SpecialtyId
                },
                slotDuration = slotDuration
            },
            slots = slotsDisponiveis,
            totalSlots = slotsDisponiveis.Count
        });
    }

    /// <summary>
    /// Aloca um paciente em um horário disponível (cria consulta)
    /// </summary>
    [HttpPost("appointments/allocate")]
    public async Task<IActionResult> AllocatePatient([FromBody] AllocatePatientDto dto)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        // Validar paciente (deve ser do mesmo município)
        var patient = await _context.Users
            .Include(u => u.PatientProfile)
            .FirstOrDefaultAsync(u => u.Id == dto.PatientId && 
                                     u.Role == UserRole.PATIENT &&
                                     u.PatientProfile != null &&
                                     u.PatientProfile.MunicipioId == municipioId);

        if (patient == null)
            return BadRequest(new { message = "Paciente não encontrado ou não pertence ao seu município" });

        // Validar agenda
        var schedule = await _context.Schedules
            .Include(s => s.Professional)
                .ThenInclude(p => p.ProfessionalProfile)
                    .ThenInclude(pp => pp!.Specialty)
            .FirstOrDefaultAsync(s => s.Id == dto.ScheduleId && s.IsActive);

        if (schedule == null)
            return BadRequest(new { message = "Agenda não encontrada ou inativa" });

        // Validar data
        if (!DateTime.TryParse(dto.Date, out var appointmentDate))
            return BadRequest(new { message = "Data inválida" });

        if (appointmentDate.Date < DateTime.Today)
            return BadRequest(new { message = "Não é possível agendar para datas passadas" });

        // Validar horário
        if (!TimeSpan.TryParse(dto.Time, out var appointmentTime))
            return BadRequest(new { message = "Horário inválido" });

        // Verificar se o horário já está ocupado
        var horarioOcupado = await _context.Appointments
            .AnyAsync(a => a.ProfessionalId == schedule.ProfessionalId &&
                          a.Date.Date == appointmentDate.Date &&
                          a.Time == appointmentTime &&
                          (a.Status == AppointmentStatus.Scheduled || a.Status == AppointmentStatus.Confirmed));

        if (horarioOcupado)
            return BadRequest(new { message = "Este horário já está ocupado. Por favor, escolha outro." });

        // Obter duração do slot da agenda
        var globalConfigAlloc = new GlobalConfigDto();
        try
        {
            if (!string.IsNullOrEmpty(schedule.GlobalConfigJson))
                globalConfigAlloc = System.Text.Json.JsonSerializer.Deserialize<GlobalConfigDto>(schedule.GlobalConfigJson) ?? new GlobalConfigDto();
        }
        catch { }
        var slotDurationAlloc = globalConfigAlloc.ConsultationDuration > 0 ? globalConfigAlloc.ConsultationDuration : 30;

        // Criar a consulta
        var specialtyId = schedule.Professional.ProfessionalProfile?.SpecialtyId;
        if (specialtyId == null)
            return BadRequest(new { message = "Profissional não possui especialidade configurada" });

        var appointment = new Appointment
        {
            PatientId = dto.PatientId,
            ProfessionalId = schedule.ProfessionalId,
            SpecialtyId = specialtyId.Value,
            Date = appointmentDate,
            Time = appointmentTime,
            EndTime = appointmentTime.Add(TimeSpan.FromMinutes(slotDurationAlloc)),
            Type = AppointmentType.Routine, // Consulta de rotina agendada pelo regulador
            Status = AppointmentStatus.Scheduled,
            Observation = dto.Observation ?? $"Consulta agendada pelo Regulador Municipal",
            CreatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(appointment);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Regulador alocou paciente {PatientId} na agenda {ScheduleId} para {Date} às {Time}",
            dto.PatientId, dto.ScheduleId, dto.Date, dto.Time);

        return Ok(new
        {
            message = "Paciente alocado com sucesso",
            appointment = new
            {
                id = appointment.Id,
                date = appointment.Date.ToString("yyyy-MM-dd"),
                time = appointment.Time.ToString(@"hh\:mm"),
                patient = new
                {
                    id = patient.Id,
                    name = patient.Name + " " + patient.LastName
                },
                professional = new
                {
                    id = schedule.Professional.Id,
                    name = schedule.Professional.Name + " " + schedule.Professional.LastName
                },
                specialty = schedule.Professional.ProfessionalProfile?.Specialty?.Name
            }
        });
    }

    private static TimeSpan CalculateEndTime(TimeSpan startTime, int durationMinutes)
    {
        return startTime.Add(TimeSpan.FromMinutes(durationMinutes));
    }

    private static string GetDayOfWeekPt(DayOfWeek day) => day switch
    {
        DayOfWeek.Sunday => "Domingo",
        DayOfWeek.Monday => "Segunda-feira",
        DayOfWeek.Tuesday => "Terça-feira",
        DayOfWeek.Wednesday => "Quarta-feira",
        DayOfWeek.Thursday => "Quinta-feira",
        DayOfWeek.Friday => "Sexta-feira",
        DayOfWeek.Saturday => "Sábado",
        _ => day.ToString()
    };

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

    /// <summary>
    /// Cadastra um novo paciente no município
    /// </summary>
    [HttpPost("patients")]
    public async Task<IActionResult> CreatePatient([FromBody] CreatePatientDto dto)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        // Validar CPF único
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Cpf == dto.Cpf);
        if (existingUser != null)
            return BadRequest(new { message = "Já existe um usuário cadastrado com este CPF" });

        // Validar CNS único se informado
        if (!string.IsNullOrWhiteSpace(dto.Cns))
        {
            var existingCns = await _context.PatientProfiles
                .AnyAsync(pp => pp.Cns == dto.Cns);
            if (existingCns)
                return BadRequest(new { message = "Já existe um paciente cadastrado com este CNS" });
        }

        // Criar usuário
        var user = new User
        {
            Name = dto.Name,
            LastName = dto.LastName,
            Email = dto.Email ?? $"{dto.Cpf.Replace(".", "").Replace("-", "")}@paciente.telecuidar.local",
            Cpf = dto.Cpf,
            Phone = dto.Phone,
            Role = UserRole.PATIENT,
            Status = UserStatus.Active,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("mudar123"), // Senha padrão
            MunicipioId = municipioId,
            CreatedAt = DateTime.UtcNow,
            EmailVerified = true // Pacientes cadastrados pelo regulador já estão verificados
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        // Criar perfil do paciente
        var profile = new PatientProfile
        {
            UserId = user.Id,
            Cns = dto.Cns,
            SocialName = dto.SocialName,
            Gender = dto.Gender,
            BirthDate = dto.BirthDate,
            MotherName = dto.MotherName,
            FatherName = dto.FatherName,
            Nationality = dto.Nationality,
            RacaCor = dto.RacaCor,
            ZipCode = dto.ZipCode,
            Logradouro = dto.Logradouro,
            Numero = dto.Numero,
            Complemento = dto.Complemento,
            Bairro = dto.Bairro,
            City = dto.City,
            State = dto.State,
            MunicipioId = municipioId,
            UnidadeAdscritaId = dto.UnidadeAdscritaId,
            ResponsavelNome = dto.ResponsavelNome,
            ResponsavelCpf = dto.ResponsavelCpf,
            ResponsavelTelefone = dto.ResponsavelTelefone,
            ResponsavelEmail = dto.ResponsavelEmail,
            ResponsavelGrauParentesco = dto.ResponsavelGrauParentesco,
            CreatedAt = DateTime.UtcNow
        };

        _context.PatientProfiles.Add(profile);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Paciente {Nome} cadastrado pelo regulador no município {MunicipioId}", 
            user.Name + " " + user.LastName, municipioId);

        return CreatedAtAction(nameof(GetPatientDetails), new { patientId = user.Id }, new
        {
            id = user.Id,
            fullName = user.Name + " " + user.LastName,
            cpf = user.Cpf,
            cns = profile.Cns
        });
    }

    /// <summary>
    /// Atualiza dados de um paciente
    /// </summary>
    [HttpPut("patients/{patientId}")]
    public async Task<IActionResult> UpdatePatient(Guid patientId, [FromBody] UpdatePatientDto dto)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        // Buscar usuário e perfil
        var user = await _context.Users
            .Include(u => u.PatientProfile)
            .FirstOrDefaultAsync(u => u.Id == patientId && u.Role == UserRole.PATIENT);

        if (user == null)
            return NotFound(new { message = "Paciente não encontrado" });

        // Verificar se pertence ao município
        if (user.PatientProfile?.MunicipioId != municipioId)
            return Forbid("Paciente não pertence ao seu município");

        // Validar CNS único se alterado
        if (!string.IsNullOrWhiteSpace(dto.Cns) && dto.Cns != user.PatientProfile?.Cns)
        {
            var existingCns = await _context.PatientProfiles
                .AnyAsync(pp => pp.Cns == dto.Cns && pp.UserId != patientId);
            if (existingCns)
                return BadRequest(new { message = "Já existe outro paciente cadastrado com este CNS" });
        }

        // Atualizar dados do usuário
        if (!string.IsNullOrWhiteSpace(dto.Name)) user.Name = dto.Name;
        if (!string.IsNullOrWhiteSpace(dto.LastName)) user.LastName = dto.LastName;
        if (!string.IsNullOrWhiteSpace(dto.Phone)) user.Phone = dto.Phone;
        user.UpdatedAt = DateTime.UtcNow;

        // Atualizar perfil
        var profile = user.PatientProfile!;
        if (dto.Cns != null) profile.Cns = dto.Cns;
        if (dto.SocialName != null) profile.SocialName = dto.SocialName;
        if (dto.Gender != null) profile.Gender = dto.Gender;
        if (dto.BirthDate.HasValue) profile.BirthDate = dto.BirthDate;
        if (dto.MotherName != null) profile.MotherName = dto.MotherName;
        if (dto.FatherName != null) profile.FatherName = dto.FatherName;
        if (dto.Nationality != null) profile.Nationality = dto.Nationality;
        if (dto.RacaCor != null) profile.RacaCor = dto.RacaCor;
        if (dto.ZipCode != null) profile.ZipCode = dto.ZipCode;
        if (dto.Logradouro != null) profile.Logradouro = dto.Logradouro;
        if (dto.Numero != null) profile.Numero = dto.Numero;
        if (dto.Complemento != null) profile.Complemento = dto.Complemento;
        if (dto.Bairro != null) profile.Bairro = dto.Bairro;
        if (dto.City != null) profile.City = dto.City;
        if (dto.State != null) profile.State = dto.State;
        if (dto.UnidadeAdscritaId.HasValue) profile.UnidadeAdscritaId = dto.UnidadeAdscritaId;
        if (dto.ResponsavelNome != null) profile.ResponsavelNome = dto.ResponsavelNome;
        if (dto.ResponsavelCpf != null) profile.ResponsavelCpf = dto.ResponsavelCpf;
        if (dto.ResponsavelTelefone != null) profile.ResponsavelTelefone = dto.ResponsavelTelefone;
        if (dto.ResponsavelEmail != null) profile.ResponsavelEmail = dto.ResponsavelEmail;
        if (dto.ResponsavelGrauParentesco != null) profile.ResponsavelGrauParentesco = dto.ResponsavelGrauParentesco;
        profile.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        _logger.LogInformation("Paciente {PatientId} atualizado pelo regulador", patientId);

        return Ok(new { message = "Paciente atualizado com sucesso" });
    }

    /// <summary>
    /// Lista unidades de saúde do município para dropdown
    /// </summary>
    [HttpGet("health-facilities")]
    public async Task<IActionResult> GetHealthFacilities()
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        var facilities = await _context.HealthFacilities
            .AsNoTracking()
            .Where(h => h.MunicipioId == municipioId && h.Ativo)
            .OrderBy(h => h.NomeFantasia)
            .Select(h => new
            {
                id = h.Id,
                codigoCnes = h.CodigoCNES,
                nome = h.NomeFantasia,
                tipo = h.TipoEstabelecimentoDescricao
            })
            .ToListAsync();

        return Ok(facilities);
    }

    /// <summary>
    /// Importa pacientes a partir de CSV (formato e-SUS/APS)
    /// Colunas esperadas: CPF, CNS, NOME, SOBRENOME, DATA_NASCIMENTO, SEXO, NOME_MAE, 
    /// NOME_PAI, TELEFONE, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, EMAIL
    /// </summary>
    [HttpPost("patients/import-csv")]
    [RequestSizeLimit(10_000_000)] // 10MB
    public async Task<IActionResult> ImportPatientsFromCsv([FromForm] IFormFile file)
    {
        var municipioId = await GetRegulatorMunicipioIdAsync();
        if (municipioId == null)
            return BadRequest(new { message = "Regulador não está vinculado a nenhum município" });

        if (file == null || file.Length == 0)
            return BadRequest(new { message = "Arquivo não enviado" });

        var extension = Path.GetExtension(file.FileName).ToLower();
        if (extension != ".csv")
            return BadRequest(new { message = "Apenas arquivos .csv são aceitos" });

        var results = new ImportCsvResult();
        var lineNumber = 0;

        try
        {
            using var reader = new StreamReader(file.OpenReadStream(), System.Text.Encoding.UTF8);
            var headerLine = await reader.ReadLineAsync();
            if (string.IsNullOrWhiteSpace(headerLine))
                return BadRequest(new { message = "Arquivo vazio ou sem cabeçalho" });

            // Detectar separador (vírgula ou ponto-e-vírgula)
            var separator = headerLine.Contains(';') ? ';' : ',';
            var headers = headerLine.Split(separator).Select(h => h.Trim().ToUpper().Replace("\"", "")).ToArray();

            // Mapear colunas (flexível para diferentes formatos)
            var columnMap = new Dictionary<string, int>();
            for (int i = 0; i < headers.Length; i++)
            {
                var col = headers[i];
                if (col.Contains("CPF") || col == "NUMERO_CADASTRO") columnMap["CPF"] = i;
                else if (col.Contains("CNS") || col == "NUMERO_CNS" || col == "CARTAO_SUS") columnMap["CNS"] = i;
                else if (col == "NOME" || col == "NOME_CIDADAO" || col == "PRIMEIRO_NOME") columnMap["NOME"] = i;
                else if (col.Contains("SOBRENOME") || col == "ULTIMO_NOME" || col == "NOME_FAMILIA") columnMap["SOBRENOME"] = i;
                else if (col.Contains("NASCIMENTO") || col == "DT_NASCIMENTO" || col == "DATA_NASC") columnMap["DATA_NASCIMENTO"] = i;
                else if (col == "SEXO" || col == "GENERO") columnMap["SEXO"] = i;
                else if (col.Contains("MAE") || col == "NOME_MAE") columnMap["NOME_MAE"] = i;
                else if (col.Contains("PAI") || col == "NOME_PAI") columnMap["NOME_PAI"] = i;
                else if (col.Contains("TELEFONE") || col.Contains("CELULAR") || col == "FONE") columnMap["TELEFONE"] = i;
                else if (col == "CEP" || col.Contains("CODIGO_POSTAL")) columnMap["CEP"] = i;
                else if (col.Contains("LOGRADOURO") || col == "ENDERECO" || col == "RUA") columnMap["LOGRADOURO"] = i;
                else if (col == "NUMERO" || col == "NUM" || col == "NRO") columnMap["NUMERO"] = i;
                else if (col.Contains("COMPLEMENTO")) columnMap["COMPLEMENTO"] = i;
                else if (col.Contains("BAIRRO")) columnMap["BAIRRO"] = i;
                else if (col.Contains("EMAIL") || col == "E-MAIL") columnMap["EMAIL"] = i;
                else if (col.Contains("NOME_SOCIAL")) columnMap["NOME_SOCIAL"] = i;
                else if (col.Contains("RACA") || col.Contains("COR")) columnMap["RACA_COR"] = i;
                else if (col.Contains("NACIONALIDADE")) columnMap["NACIONALIDADE"] = i;
            }

            // Validar colunas obrigatórias
            if (!columnMap.ContainsKey("CPF") && !columnMap.ContainsKey("CNS"))
                return BadRequest(new { message = "O arquivo deve conter coluna CPF ou CNS" });

            if (!columnMap.ContainsKey("NOME"))
                return BadRequest(new { message = "O arquivo deve conter coluna NOME" });

            // Buscar CPFs e CNS existentes para validação rápida
            var existingCpfs = await _context.Users
                .AsNoTracking()
                .Select(u => u.Cpf)
                .ToListAsync();
            var existingCpfsSet = new HashSet<string>(existingCpfs.Where(c => c != null)!);

            var existingCns = await _context.PatientProfiles
                .AsNoTracking()
                .Where(p => p.Cns != null)
                .Select(p => p.Cns!)
                .ToListAsync();
            var existingCnsSet = new HashSet<string>(existingCns);

            // Processar linhas
            while (!reader.EndOfStream)
            {
                lineNumber++;
                var line = await reader.ReadLineAsync();
                if (string.IsNullOrWhiteSpace(line)) continue;

                var values = ParseCsvLine(line, separator);
                
                string GetValue(string key) => 
                    columnMap.TryGetValue(key, out var idx) && idx < values.Length 
                        ? values[idx].Trim().Replace("\"", "") 
                        : "";

                try
                {
                    var cpf = CleanCpf(GetValue("CPF"));
                    var cns = CleanCns(GetValue("CNS"));
                    var nome = GetValue("NOME");
                    var sobrenome = GetValue("SOBRENOME");

                    // Validações
                    if (string.IsNullOrWhiteSpace(cpf) && string.IsNullOrWhiteSpace(cns))
                    {
                        results.Errors.Add(new ImportError { Line = lineNumber, Message = "CPF ou CNS é obrigatório" });
                        continue;
                    }

                    if (string.IsNullOrWhiteSpace(nome))
                    {
                        results.Errors.Add(new ImportError { Line = lineNumber, Message = "Nome é obrigatório" });
                        continue;
                    }

                    // Se CPF vazio mas CNS preenchido, aceita
                    if (string.IsNullOrWhiteSpace(cpf) && !string.IsNullOrWhiteSpace(cns))
                    {
                        // Gerar CPF fictício baseado no CNS para garantir uniqueness
                        cpf = "00000000000"; // Será tratado como paciente sem CPF
                    }

                    // Validar CPF
                    if (!string.IsNullOrWhiteSpace(cpf) && cpf != "00000000000" && !IsValidCpf(cpf))
                    {
                        results.Errors.Add(new ImportError { Line = lineNumber, Message = $"CPF inválido: {cpf}", Data = nome });
                        continue;
                    }

                    // Verificar duplicidade CPF
                    if (!string.IsNullOrWhiteSpace(cpf) && cpf != "00000000000" && existingCpfsSet.Contains(cpf))
                    {
                        results.Skipped.Add(new ImportSkipped { Line = lineNumber, Reason = "CPF já cadastrado", Data = $"{nome} - CPF: {cpf}" });
                        continue;
                    }

                    // Verificar duplicidade CNS
                    if (!string.IsNullOrWhiteSpace(cns) && existingCnsSet.Contains(cns))
                    {
                        results.Skipped.Add(new ImportSkipped { Line = lineNumber, Reason = "CNS já cadastrado", Data = $"{nome} - CNS: {cns}" });
                        continue;
                    }

                    // Parse data nascimento
                    DateTime? birthDate = null;
                    var dtNasc = GetValue("DATA_NASCIMENTO");
                    if (!string.IsNullOrWhiteSpace(dtNasc))
                    {
                        if (DateTime.TryParse(dtNasc, out var dt))
                            birthDate = dt;
                        else if (DateTime.TryParseExact(dtNasc, new[] { "dd/MM/yyyy", "ddMMyyyy", "yyyy-MM-dd" }, 
                            System.Globalization.CultureInfo.InvariantCulture, 
                            System.Globalization.DateTimeStyles.None, out dt))
                            birthDate = dt;
                    }

                    // Parse sexo
                    var sexo = GetValue("SEXO").ToUpper();
                    var gender = sexo switch
                    {
                        "M" or "MASCULINO" => "M",
                        "F" or "FEMININO" => "F",
                        _ => null
                    };

                    // Se sobrenome vazio, tentar extrair do nome completo
                    if (string.IsNullOrWhiteSpace(sobrenome) && nome.Contains(' '))
                    {
                        var parts = nome.Split(' ', 2);
                        nome = parts[0];
                        sobrenome = parts.Length > 1 ? parts[1] : "";
                    }

                    if (string.IsNullOrWhiteSpace(sobrenome))
                        sobrenome = "-"; // Default para sobrenome

                    // Criar usuário
                    var email = GetValue("EMAIL");
                    if (string.IsNullOrWhiteSpace(email))
                        email = $"{cpf.Replace(".", "").Replace("-", "")}@paciente.telecuidar.local";

                    var user = new User
                    {
                        Name = CapitalizeName(nome),
                        LastName = CapitalizeName(sobrenome),
                        Email = email,
                        Cpf = cpf,
                        Phone = CleanPhone(GetValue("TELEFONE")),
                        Role = UserRole.PATIENT,
                        Status = UserStatus.Active,
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword("mudar123"),
                        MunicipioId = municipioId,
                        CreatedAt = DateTime.UtcNow,
                        EmailVerified = true
                    };

                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();

                    // Criar perfil
                    var profile = new PatientProfile
                    {
                        UserId = user.Id,
                        Cns = string.IsNullOrWhiteSpace(cns) ? null : cns,
                        SocialName = GetValue("NOME_SOCIAL"),
                        Gender = gender,
                        BirthDate = birthDate,
                        MotherName = CapitalizeName(GetValue("NOME_MAE")),
                        FatherName = CapitalizeName(GetValue("NOME_PAI")),
                        Nationality = GetValue("NACIONALIDADE") ?? "Brasileira",
                        RacaCor = GetValue("RACA_COR"),
                        ZipCode = CleanCep(GetValue("CEP")),
                        Logradouro = GetValue("LOGRADOURO"),
                        Numero = GetValue("NUMERO"),
                        Complemento = GetValue("COMPLEMENTO"),
                        Bairro = GetValue("BAIRRO"),
                        MunicipioId = municipioId,
                        CreatedAt = DateTime.UtcNow
                    };

                    _context.PatientProfiles.Add(profile);
                    await _context.SaveChangesAsync();

                    // Adicionar aos sets para evitar duplicatas no mesmo arquivo
                    if (!string.IsNullOrWhiteSpace(cpf) && cpf != "00000000000")
                        existingCpfsSet.Add(cpf);
                    if (!string.IsNullOrWhiteSpace(cns))
                        existingCnsSet.Add(cns);

                    results.Imported.Add(new ImportSuccess { Line = lineNumber, Name = $"{user.Name} {user.LastName}", Cpf = cpf, Cns = cns });
                }
                catch (Exception ex)
                {
                    results.Errors.Add(new ImportError { Line = lineNumber, Message = $"Erro ao processar: {ex.Message}" });
                }
            }

            _logger.LogInformation("Importação CSV: {Imported} importados, {Skipped} ignorados, {Errors} erros", 
                results.Imported.Count, results.Skipped.Count, results.Errors.Count);

            return Ok(results);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro na importação CSV na linha {Line}", lineNumber);
            return StatusCode(500, new { message = $"Erro ao processar arquivo: {ex.Message}" });
        }
    }

    /// <summary>
    /// Retorna modelo de CSV para download
    /// </summary>
    [HttpGet("patients/csv-template")]
    public IActionResult GetCsvTemplate()
    {
        var csv = "CPF;CNS;NOME;SOBRENOME;DATA_NASCIMENTO;SEXO;NOME_MAE;NOME_PAI;TELEFONE;CEP;LOGRADOURO;NUMERO;COMPLEMENTO;BAIRRO;EMAIL\n";
        csv += "12345678901;123456789012345;MARIA;SILVA;01/01/1990;F;ANA SILVA;;11999999999;01310100;Av Paulista;1000;Apto 10;Bela Vista;maria@email.com\n";
        csv += "98765432100;;JOSE;SANTOS;15/05/1985;M;ROSA SANTOS;PEDRO SANTOS;11988888888;01310200;Rua Augusta;500;;Consolacao;\n";

        var bytes = System.Text.Encoding.UTF8.GetBytes(csv);
        return File(bytes, "text/csv", "modelo_importacao_pacientes.csv");
    }

    // === Helpers para importação ===
    private static string[] ParseCsvLine(string line, char separator)
    {
        var result = new List<string>();
        var current = new System.Text.StringBuilder();
        var inQuotes = false;

        foreach (var c in line)
        {
            if (c == '"')
                inQuotes = !inQuotes;
            else if (c == separator && !inQuotes)
            {
                result.Add(current.ToString());
                current.Clear();
            }
            else
                current.Append(c);
        }
        result.Add(current.ToString());
        return result.ToArray();
    }

    private static string CleanCpf(string cpf)
    {
        if (string.IsNullOrWhiteSpace(cpf)) return "";
        return new string(cpf.Where(char.IsDigit).ToArray()).PadLeft(11, '0');
    }

    private static string CleanCns(string cns)
    {
        if (string.IsNullOrWhiteSpace(cns)) return "";
        return new string(cns.Where(char.IsDigit).ToArray());
    }

    private static string CleanCep(string cep)
    {
        if (string.IsNullOrWhiteSpace(cep)) return "";
        return new string(cep.Where(char.IsDigit).ToArray());
    }

    private static string CleanPhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return "";
        return new string(phone.Where(char.IsDigit).ToArray());
    }

    private static bool IsValidCpf(string cpf)
    {
        if (string.IsNullOrWhiteSpace(cpf) || cpf.Length != 11) return false;
        if (cpf.Distinct().Count() == 1) return false; // Todos dígitos iguais

        int[] mult1 = { 10, 9, 8, 7, 6, 5, 4, 3, 2 };
        int[] mult2 = { 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 };

        var tempCpf = cpf.Substring(0, 9);
        var sum = tempCpf.Select((c, i) => (c - '0') * mult1[i]).Sum();
        var rest = sum % 11;
        var digit1 = rest < 2 ? 0 : 11 - rest;

        tempCpf += digit1;
        sum = tempCpf.Select((c, i) => (c - '0') * mult2[i]).Sum();
        rest = sum % 11;
        var digit2 = rest < 2 ? 0 : 11 - rest;

        return cpf.EndsWith($"{digit1}{digit2}");
    }

    private static string CapitalizeName(string? name)
    {
        if (string.IsNullOrWhiteSpace(name)) return "";
        var words = name.ToLower().Split(' ');
        var prepositions = new HashSet<string> { "de", "da", "do", "das", "dos", "e" };
        return string.Join(" ", words.Select((w, i) => 
            i > 0 && prepositions.Contains(w) ? w : char.ToUpper(w[0]) + w[1..]));
    }

    /// <summary>
    /// Obtém informações de diagnóstico do serviço CADSUS/CNS
    /// Útil para verificar configuração do certificado em produção
    /// </summary>
    [HttpGet("cadsus/diagnostics")]
    public IActionResult GetCadsusDiagnostics()
    {
        _logger.LogInformation("Solicitação de diagnóstico CADSUS");
        var diagnostics = _cnsService.GetDiagnostics();
        return Ok(diagnostics);
    }

    /// <summary>
    /// Busca cidadão no CADSUS por CPF ou CNS
    /// NOTA: Versão simulada para POC - substituir por integração real com webservice CADSUS
    /// </summary>
    [HttpGet("cadsus/search")]
    public async Task<IActionResult> SearchCadsus([FromQuery] string? cpf, [FromQuery] string? cns)
    {
        // Validar que pelo menos um parâmetro foi fornecido
        if (string.IsNullOrWhiteSpace(cpf) && string.IsNullOrWhiteSpace(cns))
            return BadRequest(new { message = "Informe CPF ou CNS para busca" });


        // Limpar formatação
        var cleanCpf = !string.IsNullOrWhiteSpace(cpf) ? new string(cpf.Where(char.IsDigit).ToArray()) : null;
        var cleanCns = !string.IsNullOrWhiteSpace(cns) ? new string(cns.Where(char.IsDigit).ToArray()) : null;

        // Validar CPF se fornecido
        if (!string.IsNullOrWhiteSpace(cleanCpf) && !IsValidCpf(cleanCpf))
            return BadRequest(new { message = "CPF inválido" });

        // Validar CNS se fornecido (deve ter 15 dígitos)
        if (!string.IsNullOrWhiteSpace(cleanCns) && cleanCns.Length != 15)
            return BadRequest(new { message = "CNS deve ter 15 dígitos" });

        _logger.LogInformation("Buscando CADSUS - CPF: {Cpf}, CNS: {Cns}", 
            !string.IsNullOrWhiteSpace(cleanCpf) ? $"***{cleanCpf[^4..]}" : "N/A",
            !string.IsNullOrWhiteSpace(cleanCns) ? $"***{cleanCns[^4..]}" : "N/A");

        // === SIMULAÇÃO CADSUS para POC ===
        // Em produção, substituir por chamada ao webservice real do CADSUS
        // Documentação: https://datasus.saude.gov.br/cadsus-web/
        
        // Primeiro verificar se já existe no banco local
        var existingPatient = await _context.Users
            .AsNoTracking()
            .Include(u => u.PatientProfile)
            .Where(u => u.Role == UserRole.PATIENT &&
                       ((!string.IsNullOrWhiteSpace(cleanCpf) && u.Cpf == cleanCpf) ||
                        (!string.IsNullOrWhiteSpace(cleanCns) && u.PatientProfile != null && u.PatientProfile.Cns == cleanCns)))
            .Select(u => new CadsusResult
            {
                Found = true,
                Source = "LOCAL",
                Cpf = u.Cpf,
                Cns = u.PatientProfile != null ? u.PatientProfile.Cns : null,
                Nome = u.Name,
                NomeSocial = u.PatientProfile != null ? u.PatientProfile.SocialName : null,
                Sobrenome = u.LastName,
                DataNascimento = u.PatientProfile != null ? u.PatientProfile.BirthDate : null,
                Sexo = u.PatientProfile != null ? u.PatientProfile.Gender : null,
                NomeMae = u.PatientProfile != null ? u.PatientProfile.MotherName : null,
                NomePai = u.PatientProfile != null ? u.PatientProfile.FatherName : null,
                Nacionalidade = u.PatientProfile != null ? u.PatientProfile.Nationality : null,
                RacaCor = u.PatientProfile != null ? u.PatientProfile.RacaCor : null,
                Telefone = u.Phone,
                Email = u.Email,
                Cep = u.PatientProfile != null ? u.PatientProfile.ZipCode : null,
                Logradouro = u.PatientProfile != null ? u.PatientProfile.Logradouro : null,
                Numero = u.PatientProfile != null ? u.PatientProfile.Numero : null,
                Complemento = u.PatientProfile != null ? u.PatientProfile.Complemento : null,
                Bairro = u.PatientProfile != null ? u.PatientProfile.Bairro : null,
                Municipio = u.PatientProfile != null ? u.PatientProfile.City : null,
                Uf = u.PatientProfile != null ? u.PatientProfile.State : null,
                AlreadyRegistered = true,
                LocalPatientId = u.Id.ToString()
            })
            .FirstOrDefaultAsync();

        if (existingPatient != null)
            return Ok(existingPatient);

        // === INTEGRAÇÃO REAL COM CADSUS ===
        // Se o serviço CNS está configurado (certificado digital), usar a API real
        if (_cnsService.IsConfigured() && !string.IsNullOrWhiteSpace(cleanCpf))
        {
            try
            {
                _logger.LogInformation("CNS Service configurado - consultando CADSUS real para CPF: ***{CpfSuffix}", cleanCpf[^4..]);
                
                var cadsusData = await _cnsService.ConsultarCpfAsync(cleanCpf);
                
                // Verifica se encontrou (Nome não vazio)
                if (cadsusData != null && !string.IsNullOrWhiteSpace(cadsusData.Nome))
                {
                    _logger.LogInformation("Cidadão encontrado no CADSUS: {Nome}", cadsusData.Nome);
                    
                    // Extrai primeiro nome e sobrenome
                    var textInfo = System.Globalization.CultureInfo.GetCultureInfo("pt-BR").TextInfo;
                    var nomeCompleto = cadsusData.Nome.Trim();
                    var partesNome = nomeCompleto.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
                    var primeiroNome = partesNome.Length > 0 ? textInfo.ToTitleCase(partesNome[0].ToLower()) : "";
                    var sobrenome = partesNome.Length > 1 ? textInfo.ToTitleCase(partesNome[1].ToLower()) : "";
                    
                    // Pega primeiro telefone e email se disponíveis
                    var telefone = cadsusData.Telefones?.FirstOrDefault() ?? "";
                    var email = cadsusData.Emails?.FirstOrDefault() ?? "";
                    
                    // Parse data de nascimento (formato DD/MM/YYYY ou YYYY-MM-DD)
                    DateTime? dataNasc = null;
                    if (!string.IsNullOrEmpty(cadsusData.DataNascimento))
                    {
                        if (DateTime.TryParseExact(cadsusData.DataNascimento, "dd/MM/yyyy", null, System.Globalization.DateTimeStyles.None, out var dt1))
                            dataNasc = dt1;
                        else if (DateTime.TryParse(cadsusData.DataNascimento, out var dt2))
                            dataNasc = dt2;
                    }
                    
                    // Determina nacionalidade
                    var nacionalidade = "Brasileira";
                    if (!string.IsNullOrEmpty(cadsusData.PaisNascimento) && !cadsusData.PaisNascimento.Contains("Brasil", StringComparison.OrdinalIgnoreCase))
                        nacionalidade = cadsusData.PaisNascimento;
                    
                    return Ok(new CadsusResult
                    {
                        Found = true,
                        Source = "CADSUS",
                        Cpf = cadsusData.Cpf,
                        Cns = cadsusData.Cns?.Split(',').FirstOrDefault()?.Trim() ?? "",
                        Nome = primeiroNome,
                        Sobrenome = sobrenome,
                        DataNascimento = dataNasc,
                        Sexo = cadsusData.Sexo,
                        NomeMae = !string.IsNullOrEmpty(cadsusData.NomeMae) ? textInfo.ToTitleCase(cadsusData.NomeMae.ToLower()) : "",
                        NomePai = !string.IsNullOrEmpty(cadsusData.NomePai) ? textInfo.ToTitleCase(cadsusData.NomePai.ToLower()) : "",
                        RacaCor = cadsusData.RacaCor,
                        Telefone = telefone,
                        Email = email,
                        Cep = cadsusData.Cep,
                        Logradouro = !string.IsNullOrEmpty(cadsusData.Logradouro) ? textInfo.ToTitleCase(cadsusData.Logradouro.ToLower()) : "",
                        Numero = cadsusData.Numero,
                        Complemento = cadsusData.Complemento,
                        Bairro = "", // CADSUS não retorna bairro separado
                        Municipio = !string.IsNullOrEmpty(cadsusData.Cidade) ? textInfo.ToTitleCase(cadsusData.Cidade.ToLower()) : "",
                        Uf = cadsusData.Uf,
                        Nacionalidade = nacionalidade,
                        AlreadyRegistered = false
                    });
                }
                else
                {
                    _logger.LogInformation("Cidadão não encontrado no CADSUS");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao consultar CADSUS real: {Message}", ex.Message);
                // Em caso de erro, continua para simulação ou retorna não encontrado
            }
        }
        else if (!_cnsService.IsConfigured())
        {
            _logger.LogInformation("CNS Service não configurado - usando simulação para POC");
            
            // Simulação para POC - remover quando certificado estiver configurado
            var simulatedResult = SimulateCadsusLookup(cleanCpf, cleanCns);
            if (simulatedResult != null)
                return Ok(simulatedResult);
        }

        // Não encontrado
        return Ok(new CadsusResult
        {
            Found = false,
            Source = "CADSUS",
            Message = "Cidadão não encontrado no CADSUS"
        });
    }

    /// <summary>
    /// Simula resposta do CADSUS para demonstração - REMOVER EM PRODUÇÃO
    /// </summary>
    private static CadsusResult? SimulateCadsusLookup(string? cpf, string? cns)
    {
        // Dados fictícios para demonstração do fluxo
        // Estes CPFs de teste retornam dados simulados
        var testData = new Dictionary<string, CadsusResult>
        {
            ["11122233344"] = new CadsusResult
            {
                Found = true,
                Source = "CADSUS",
                Cpf = "11122233344",
                Cns = "123456789012345",
                Nome = "João",
                Sobrenome = "da Silva Santos",
                DataNascimento = new DateTime(1985, 5, 15),
                Sexo = "M",
                NomeMae = "Maria da Silva",
                NomePai = "José Santos",
                Nacionalidade = "Brasileira",
                RacaCor = "Parda",
                Cep = "01310100",
                Logradouro = "Avenida Paulista",
                Numero = "1000",
                Bairro = "Bela Vista",
                Municipio = "São Paulo",
                Uf = "SP",
                AlreadyRegistered = false
            },
            ["22233344455"] = new CadsusResult
            {
                Found = true,
                Source = "CADSUS",
                Cpf = "22233344455",
                Cns = "234567890123456",
                Nome = "Maria",
                Sobrenome = "Oliveira Costa",
                DataNascimento = new DateTime(1990, 8, 22),
                Sexo = "F",
                NomeMae = "Ana Oliveira",
                Nacionalidade = "Brasileira",
                RacaCor = "Branca",
                Cep = "22041080",
                Logradouro = "Rua Barata Ribeiro",
                Numero = "500",
                Complemento = "Apto 201",
                Bairro = "Copacabana",
                Municipio = "Rio de Janeiro",
                Uf = "RJ",
                AlreadyRegistered = false
            },
            ["33344455566"] = new CadsusResult
            {
                Found = true,
                Source = "CADSUS",
                Cpf = "33344455566",
                Cns = "345678901234567",
                Nome = "Pedro",
                Sobrenome = "Ferreira Lima",
                DataNascimento = new DateTime(1975, 12, 3),
                Sexo = "M",
                NomeMae = "Rosa Ferreira",
                NomePai = "Antônio Lima",
                Nacionalidade = "Brasileira",
                RacaCor = "Preta",
                Cep = "30130000",
                Logradouro = "Praça Sete de Setembro",
                Numero = "100",
                Bairro = "Centro",
                Municipio = "Belo Horizonte",
                Uf = "MG",
                AlreadyRegistered = false
            }
        };

        // Buscar por CPF
        if (!string.IsNullOrWhiteSpace(cpf) && testData.TryGetValue(cpf, out var resultByCpf))
            return resultByCpf;

        // Buscar por CNS
        if (!string.IsNullOrWhiteSpace(cns))
        {
            var resultByCns = testData.Values.FirstOrDefault(r => r.Cns == cns);
            if (resultByCns != null)
                return resultByCns;
        }

        return null;
    }
}

// DTO para resultado da busca CADSUS
public class CadsusResult
{
    public bool Found { get; set; }
    public string Source { get; set; } = "CADSUS"; // "CADSUS" ou "LOCAL"
    public string? Message { get; set; }
    
    // Dados do cidadão
    public string? Cpf { get; set; }
    public string? Cns { get; set; }
    public string? Nome { get; set; }
    public string? NomeSocial { get; set; }
    public string? Sobrenome { get; set; }
    public DateTime? DataNascimento { get; set; }
    public string? Sexo { get; set; }
    public string? NomeMae { get; set; }
    public string? NomePai { get; set; }
    public string? Nacionalidade { get; set; }
    public string? RacaCor { get; set; }
    public string? Telefone { get; set; }
    public string? Email { get; set; }
    
    // Endereço
    public string? Cep { get; set; }
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? Municipio { get; set; }
    public string? Uf { get; set; }
    
    // Se já está cadastrado localmente
    public bool AlreadyRegistered { get; set; }
    public string? LocalPatientId { get; set; }
}

// DTOs para resultado da importação
public class ImportCsvResult
{
    public List<ImportSuccess> Imported { get; set; } = new();
    public List<ImportSkipped> Skipped { get; set; } = new();
    public List<ImportError> Errors { get; set; } = new();
    public int TotalProcessed => Imported.Count + Skipped.Count + Errors.Count;
}

public class ImportSuccess
{
    public int Line { get; set; }
    public string Name { get; set; } = "";
    public string? Cpf { get; set; }
    public string? Cns { get; set; }
}

public class ImportSkipped
{
    public int Line { get; set; }
    public string Reason { get; set; } = "";
    public string? Data { get; set; }
}

public class ImportError
{
    public int Line { get; set; }
    public string Message { get; set; } = "";
    public string? Data { get; set; }
}

// DTO para alocação de paciente em agenda
public class AllocatePatientDto
{
    public required Guid PatientId { get; set; }
    public required Guid ScheduleId { get; set; }
    public required string Date { get; set; } // formato: yyyy-MM-dd
    public required string Time { get; set; } // formato: HH:mm
    public string? Observation { get; set; }
}

// DTO para criação de paciente
public class CreatePatientDto
{
    public required string Name { get; set; }
    public required string LastName { get; set; }
    public required string Cpf { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Cns { get; set; }
    public string? SocialName { get; set; }
    public string? Gender { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? MotherName { get; set; }
    public string? FatherName { get; set; }
    public string? Nationality { get; set; }
    public string? RacaCor { get; set; }
    public string? ZipCode { get; set; }
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public Guid? UnidadeAdscritaId { get; set; }
    public string? ResponsavelNome { get; set; }
    public string? ResponsavelCpf { get; set; }
    public string? ResponsavelTelefone { get; set; }
    public string? ResponsavelEmail { get; set; }
    public string? ResponsavelGrauParentesco { get; set; }
}

// DTO para atualização de paciente
public class UpdatePatientDto
{
    public string? Name { get; set; }
    public string? LastName { get; set; }
    public string? Phone { get; set; }
    public string? Cns { get; set; }
    public string? SocialName { get; set; }
    public string? Gender { get; set; }
    public DateTime? BirthDate { get; set; }
    public string? MotherName { get; set; }
    public string? FatherName { get; set; }
    public string? Nationality { get; set; }
    public string? RacaCor { get; set; }
    public string? ZipCode { get; set; }
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public Guid? UnidadeAdscritaId { get; set; }
    public string? ResponsavelNome { get; set; }
    public string? ResponsavelCpf { get; set; }
    public string? ResponsavelTelefone { get; set; }
    public string? ResponsavelEmail { get; set; }
    public string? ResponsavelGrauParentesco { get; set; }
}
