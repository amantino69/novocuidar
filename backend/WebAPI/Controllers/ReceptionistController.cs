using Application.Interfaces;
using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Domain.Entities;
using Domain.Enums;
using Microsoft.AspNetCore.SignalR;
using WebAPI.Hubs;
using WebAPI.Services;

namespace WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReceptionistController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IAuditLogService _auditLogService;
    private readonly IHubContext<SchedulingHub> _schedulingHub;
    private readonly IRealTimeNotificationService _realTimeNotification;
    private readonly ILogger<ReceptionistController> _logger;

    public ReceptionistController(
        ApplicationDbContext context, 
        IAuditLogService auditLogService,
        IHubContext<SchedulingHub> schedulingHub,
        IRealTimeNotificationService realTimeNotification,
        ILogger<ReceptionistController> logger)
    {
        _context = context;
        _auditLogService = auditLogService;
        _schedulingHub = schedulingHub;
        _realTimeNotification = realTimeNotification;
        _logger = logger;
    }

    private Guid? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return userIdClaim != null ? Guid.Parse(userIdClaim) : null;
    }

    /// <summary>
    /// Buscar consultas agendadas para hoje (para recepcionista)
    /// </summary>
    [HttpGet("today-appointments")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> GetTodayAppointments([FromQuery] DateTime? date = null)
    {
        var targetDate = (date ?? DateTime.Today).Date;

        var appointments = await _context.Appointments
            .Include(a => a.Patient)
            .Include(a => a.Professional)
            .Include(a => a.Specialty)
            .Where(a => a.Date >= targetDate && a.Date < targetDate.AddDays(1) && 
                       (a.Status == AppointmentStatus.Scheduled || 
                        a.Status == AppointmentStatus.Confirmed ||
                        a.Status == AppointmentStatus.CheckedIn))
            .OrderBy(a => a.Time)
            .Select(a => new
            {
                a.Id,
                a.Date,
                a.Time,
                a.Status,
                PatientName = a.Patient.Name + " " + a.Patient.LastName,
                PatientCpf = a.Patient.Cpf,
                ProfessionalName = a.Professional.Name,
                SpecialtyName = a.Specialty.Name,
                a.CheckInTime
            })
            .ToListAsync();

        return Ok(appointments);
    }

    /// <summary>
    /// Marcar presença do paciente (Check-in)
    /// </summary>
    [HttpPost("{appointmentId}/check-in")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> CheckInPatient(Guid appointmentId)
    {
        var appointment = await _context.Appointments
            .Include(a => a.Patient)
            .Include(a => a.Professional)
            .FirstOrDefaultAsync(a => a.Id == appointmentId);

        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        if (appointment.Status == AppointmentStatus.CheckedIn)
            return BadRequest(new { message = "Paciente já fez check-in" });

        if (appointment.Status != AppointmentStatus.Scheduled && appointment.Status != AppointmentStatus.Confirmed)
            return BadRequest(new { message = $"Consulta não pode receber check-in. Status atual: {appointment.Status}" });

        // Atualizar appointment
        appointment.Status = AppointmentStatus.CheckedIn;
        appointment.CheckInTime = DateTime.UtcNow;

        // Criar entrada na fila de espera
        var waitingList = new WaitingList
        {
            Id = Guid.NewGuid(),
            AppointmentId = appointment.Id,
            PatientId = appointment.PatientId,
            ProfessionalId = appointment.ProfessionalId,
            CheckInTime = DateTime.UtcNow,
            Status = WaitingListStatus.Waiting,
            Position = await GetNextPositionAsync(),
            Priority = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.WaitingLists.Add(waitingList);
        await _context.SaveChangesAsync();

        // CHECK-IN é apenas para marcar presença da recepcionista
        // Notificação para o médico só acontece quando a ENFERMEIRA ENTRA na consulta
        // (endpoint /notify-doctor é chamado pela enfermeira, não pela recepcionista)

        // Audit log
        await _auditLogService.CreateAuditLogAsync(
            GetCurrentUserId(),
            "check_in",
            "Appointment",
            appointmentId.ToString(),
            null,
            $"Paciente {appointment.Patient.Name} fez check-in",
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            HttpContext.Request.Headers["User-Agent"].ToString()
        );

        return Ok(new
        {
            Success = true,
            Message = "Check-in realizado com sucesso",
            Appointment = new
            {
                appointment.Id,
                appointment.Status,
                appointment.CheckInTime,
                Position = waitingList.Position
            }
        });
    }

    /// <summary>
    /// Buscar fila de espera atual
    /// </summary>
    [HttpGet("waiting-list")]
    [Authorize(Roles = "RECEPTIONIST,ASSISTANT,ADMIN")]
    public async Task<IActionResult> GetWaitingList()
    {
        var waitingListItems = await _context.WaitingLists
            .Include(w => w.Patient)
            .Include(w => w.Professional)
            .Include(w => w.Appointment)
            .ThenInclude(a => a.Specialty)
            .Where(w => w.Status == WaitingListStatus.Waiting || w.Status == WaitingListStatus.Called)
            .OrderByDescending(w => w.Priority)
            .ThenBy(w => w.Position)
            .AsNoTracking()
            .ToListAsync();

        var now = DateTime.UtcNow;
        var waitingList = waitingListItems.Select(w => new
        {
            w.Id,
            w.Position,
            w.Priority,
            w.Status,
            w.CheckInTime,
            WaitingTime = w.CheckInTime.HasValue
                ? (int)(now - w.CheckInTime.Value).TotalMinutes
                : 0,
            PatientName = w.Patient.Name + " " + w.Patient.LastName,
            ProfessionalName = w.Professional.Name,
            SpecialtyName = w.Appointment.Specialty.Name,
            AppointmentId = w.AppointmentId,
            AppointmentTime = w.Appointment.Time,
            // Campos de demanda espontânea
            IsSpontaneousDemand = w.IsSpontaneousDemand,
            UrgencyLevel = w.UrgencyLevel,
            ChiefComplaint = w.ChiefComplaint,
            AppointmentType = w.Appointment.Type
        });

        return Ok(waitingList);
    }

    /// <summary>
    /// Marcar paciente como ausente (No-show)
    /// </summary>
    [HttpPut("{appointmentId}/no-show")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> MarkAsNoShow(Guid appointmentId)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        appointment.Status = AppointmentStatus.NoShow;

        // Remover da fila se estiver
        var waitingEntry = await _context.WaitingLists
            .FirstOrDefaultAsync(w => w.AppointmentId == appointmentId);
        
        if (waitingEntry != null)
        {
            waitingEntry.Status = WaitingListStatus.NoShow;
        }

        await _context.SaveChangesAsync();

        // Audit log
        await _auditLogService.CreateAuditLogAsync(
            GetCurrentUserId(),
            "no_show",
            "Appointment",
            appointmentId.ToString(),
            null,
            "Paciente não compareceu",
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            HttpContext.Request.Headers["User-Agent"].ToString()
        );

        return Ok(new { Success = true, Message = "Marcado como ausente" });
    }

    /// <summary>
    /// Estatísticas do dia para recepcionista
    /// </summary>
    [HttpGet("statistics")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> GetStatistics([FromQuery] DateTime? date = null)
    {
        var targetDate = (date ?? DateTime.Today).Date;
        var nextDay = targetDate.AddDays(1);

        var totalScheduled = await _context.Appointments
            .CountAsync(a => a.Date >= targetDate && a.Date < nextDay);

        var totalCheckedIn = await _context.Appointments
            .CountAsync(a => a.Date >= targetDate && a.Date < nextDay && a.Status == AppointmentStatus.CheckedIn);

        var totalCompleted = await _context.Appointments
            .CountAsync(a => a.Date >= targetDate && a.Date < nextDay && a.Status == AppointmentStatus.Completed);

        var totalNoShow = await _context.Appointments
            .CountAsync(a => a.Date >= targetDate && a.Date < nextDay && a.Status == AppointmentStatus.NoShow);

        var currentWaiting = await _context.WaitingLists
            .CountAsync(w => w.Status == WaitingListStatus.Waiting);

        var waitTimes = await _context.WaitingLists
            .Where(w => w.CheckInTime.HasValue && w.CalledTime.HasValue)
            .Select(w => new { w.CheckInTime, w.CalledTime })
            .AsNoTracking()
            .ToListAsync();

        var avgWaitTime = waitTimes.Count > 0
            ? waitTimes.Average(w => (w.CalledTime!.Value - w.CheckInTime!.Value).TotalMinutes)
            : 0;

        return Ok(new
        {
            TotalScheduled = totalScheduled,
            TotalCheckedIn = totalCheckedIn,
            TotalCompleted = totalCompleted,
            TotalNoShow = totalNoShow,
            CurrentWaiting = currentWaiting,
            AverageWaitTimeMinutes = Math.Round(avgWaitTime, 1),
            NoShowRate = totalScheduled > 0 ? Math.Round((double)totalNoShow / totalScheduled * 100, 1) : 0
        });
    }
    /// <summary>
    /// Criar demanda espontânea (walk-in) - NOVO
    /// </summary>
    [HttpPost("spontaneous-demand")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> CreateSpontaneousDemand([FromBody] CreateSpontaneousDemandDto dto)
    {
        // Validações
        var patient = await _context.Users
            .Include(u => u.PatientProfile)
            .FirstOrDefaultAsync(u => u.Id == dto.PatientId && u.Role == UserRole.PATIENT);
            
        if (patient == null || patient.PatientProfile == null)
            return NotFound(new { message = "Paciente não encontrado" });

        var specialty = await _context.Specialties.FindAsync(dto.SpecialtyId);
        if (specialty == null)
            return NotFound(new { message = "Especialidade não encontrada" });

        // Buscar médico disponível da especialidade
        User? professional = null;
        if (dto.ProfessionalId.HasValue)
        {
            professional = await _context.Users
                .Include(u => u.ProfessionalProfile)
                .FirstOrDefaultAsync(u => u.Id == dto.ProfessionalId.Value && 
                                         u.Role == UserRole.PROFESSIONAL &&
                                         u.ProfessionalProfile!.SpecialtyId == dto.SpecialtyId);
        }
        else
        {
            // Pegar primeiro médico disponível da especialidade
            professional = await _context.Users
                .Include(u => u.ProfessionalProfile)
                .Where(u => u.Role == UserRole.PROFESSIONAL && 
                           u.ProfessionalProfile!.SpecialtyId == dto.SpecialtyId)
                .FirstOrDefaultAsync();
        }

        if (professional == null)
            return NotFound(new { message = "Nenhum médico disponível para esta especialidade" });

        // Criar consulta
        var appointment = new Appointment
        {
            Id = Guid.NewGuid(),
            PatientId = dto.PatientId,
            ProfessionalId = professional.Id,
            SpecialtyId = dto.SpecialtyId,
            Date = DateTime.Today,
            Time = DateTime.Now.TimeOfDay,
            Type = AppointmentType.SpontaneousDemand,
            Status = AppointmentStatus.CheckedIn,
            Observation = dto.ChiefComplaint,
            CheckInTime = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(appointment);

        // Criar entrada na fila com prioridade baseada na urgência
        var priority = dto.UrgencyLevel switch
        {
            UrgencyLevel.Red => 3,
            UrgencyLevel.Orange => 2,
            UrgencyLevel.Yellow => 1,
            _ => 0
        };

        var waitingList = new WaitingList
        {
            Id = Guid.NewGuid(),
            AppointmentId = appointment.Id,
            PatientId = dto.PatientId,
            ProfessionalId = professional.Id,
            CheckInTime = DateTime.UtcNow,
            Status = WaitingListStatus.Waiting,
            Position = await GetNextPositionAsync(),
            Priority = priority,
            UrgencyLevel = dto.UrgencyLevel,
            IsSpontaneousDemand = true,
            ChiefComplaint = dto.ChiefComplaint,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.WaitingLists.Add(waitingList);
        await _context.SaveChangesAsync();

            // Notificação será enviada quando a enfermeira entrar na consulta
        _logger.LogInformation($"Demanda espontânea criada para médico {professional.Id} e especialidade {dto.SpecialtyId}");
        // Audit log
        await _auditLogService.CreateAuditLogAsync(
            GetCurrentUserId(),
            "spontaneous_demand_created",
            "Appointment",
            appointment.Id.ToString(),
            null,
            $"Demanda espontânea criada: {patient.Name} - {specialty.Name} (Urgência: {dto.UrgencyLevel})",
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            HttpContext.Request.Headers["User-Agent"].ToString()
        );

        return Ok(new
        {
            Success = true,
            Message = "Demanda espontânea registrada com sucesso",
            AppointmentId = appointment.Id,
            Position = waitingList.Position,
            ProfessionalName = professional.Name,
            EstimatedWaitMinutes = CalculateEstimatedWait(priority)
        });
    }

    /// <summary>
    /// <summary>
    /// Buscar pacientes para demanda espontânea (busca rápida)
    /// </summary>
    [HttpGet("patients/search")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> SearchPatients([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query) || query.Length < 2)
            return Ok(new { data = new List<object>() });

        var queryLower = query.ToLower();
        var patients = await _context.Users
            .Include(u => u.PatientProfile)
            .Where(u => u.Role == UserRole.PATIENT &&
                       (u.Name.ToLower().Contains(queryLower) || 
                        u.LastName.ToLower().Contains(queryLower) ||
                        (u.Cpf != null && u.Cpf.Contains(query))))
            .OrderBy(u => u.Name)
            .ThenBy(u => u.LastName)
            .Take(20)
            .Select(u => new
            {
                u.Id,
                Name = u.Name + " " + u.LastName,
                u.Email,
                u.Cpf,
                BirthDate = u.PatientProfile!.BirthDate,
                Age = u.PatientProfile!.BirthDate.HasValue 
                    ? DateTime.Today.Year - u.PatientProfile.BirthDate.Value.Year 
                    : 0,
                u.Phone
            })
            .ToListAsync();

        return Ok(new { data = patients });
    }

    /// <summary>
    /// Buscar médicos disponíveis por especialidade
    /// </summary>
    [HttpGet("professionals/by-specialty/{specialtyId}")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> GetProfessionalsBySpecialty(Guid specialtyId)
    {
        var professionals = await _context.Users
            .Include(u => u.ProfessionalProfile)
            .Where(u => u.Role == UserRole.PROFESSIONAL && 
                       u.ProfessionalProfile!.SpecialtyId == specialtyId)
            .OrderBy(u => u.Name)
            .Select(u => new
            {
                u.Id,
                Name = u.Name + " " + u.LastName,
                IsOnline = false // TODO: Implementar status online via SignalR
            })
            .ToListAsync();

        return Ok(new { data = professionals });
    }

    /// <summary>
    /// <summary>
    /// Buscar todas as especialidades
    /// </summary>
    [HttpGet("specialties")]
    [Authorize(Roles = "RECEPTIONIST,ADMIN")]
    public async Task<IActionResult> GetSpecialties()
    {
        var specialties = await _context.Specialties
            .Where(s => s.Status.ToString() == "Active")
            .OrderBy(s => s.Name)
            .Distinct()
            .Select(s => new
            {
                s.Id,
                s.Name,
                s.Description,
                ProfessionalCount = s.Professionals.Count
            })
            .Distinct() // Remove duplicatas após select
            .ToListAsync();

        return Ok(new { data = specialties });
    }

    private async Task<int> GetNextPositionAsync()
    {
        var maxPosition = await _context.WaitingLists
            .Where(w => w.Status == WaitingListStatus.Waiting || w.Status == WaitingListStatus.Called)
            .MaxAsync(w => (int?)w.Position) ?? 0;
        
        return maxPosition + 1;
    }

    private int CalculateEstimatedWait(int priority)
    {
        // Estimativa simplificada baseada na prioridade
        return priority switch
        {
            3 => 5,   // Vermelho: 5 min
            2 => 15,  // Laranja: 15 min
            1 => 30,  // Amarelo: 30 min
            _ => 60   // Verde: 60 min
        };
    }

    /// <summary>
    /// Listar demandas espontâneas do dia (para recepcionista ver histórico e enfermeira ver pendentes)
    /// </summary>
    [HttpGet("spontaneous-demands")]
    [Authorize(Roles = "RECEPTIONIST,ASSISTANT,NURSE,ADMIN")]
    public async Task<IActionResult> GetSpontaneousDemands([FromQuery] DateTime? date = null, [FromQuery] bool pendingOnly = false)
    {
        var targetDate = (date ?? DateTime.Today).Date;
        var nextDay = targetDate.AddDays(1);

        var query = _context.Appointments
            .Include(a => a.Patient)
            .Include(a => a.Professional)
            .Include(a => a.Specialty)
            .Include(a => a.WaitingList)
            .Where(a => a.Type == AppointmentType.SpontaneousDemand &&
                       a.Date >= targetDate && a.Date < nextDay);

        // Se pendingOnly=true, filtra apenas demandas aguardando atendimento (Scheduled ou CheckedIn)
        if (pendingOnly)
        {
            query = query.Where(a => a.Status == AppointmentStatus.Scheduled || a.Status == AppointmentStatus.CheckedIn);
        }

        var demands = await query
            .OrderByDescending(a => a.WaitingList != null ? (int?)a.WaitingList.UrgencyLevel : null) // Mais urgentes primeiro
            .ThenBy(a => a.CreatedAt)               // Depois por ordem de chegada
            .Select(a => new
            {
                a.Id,
                a.Date,
                a.Time,
                a.Status,
                a.CheckInTime,
                UrgencyLevel = a.WaitingList != null ? a.WaitingList.UrgencyLevel.ToString() : "Green",
                PatientName = a.Patient.Name + " " + a.Patient.LastName,
                PatientCpf = a.Patient.Cpf,
                ProfessionalName = a.Professional.Name,
                SpecialtyName = a.Specialty.Name,
                ChiefComplaint = a.WaitingList != null ? a.WaitingList.ChiefComplaint : a.Observation,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();

        return Ok(new { data = demands });
    }

    /// <summary>
    /// Notificar médico que enfermeira entrou na consulta de demanda espontânea
    /// </summary>
    [HttpPost("{appointmentId}/notify-doctor")]
    [Authorize(Roles = "ASSISTANT,NURSE,ADMIN")]
    public async Task<IActionResult> NotifyDoctorAppointmentReady(Guid appointmentId)
    {
        var appointment = await _context.Appointments
            .Include(a => a.Patient)
            .Include(a => a.Professional)
            .Include(a => a.Specialty)
            .FirstOrDefaultAsync(a => a.Id == appointmentId);

        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        if (appointment.ProfessionalId == Guid.Empty)
            return BadRequest(new { message = "Consulta sem médico atribuído" });

        // Construir link da videoconferência
        var meetLink = $"/teleconsulta/{appointment.Id}";
        var isSpontaneous = appointment.Type == AppointmentType.SpontaneousDemand;
        var urgencyColor = GetUrgencyColor(appointment);

        try
        {
            // Notificar médico
            await _realTimeNotification.NotifyUserAsync(
                appointment.ProfessionalId.ToString(),
                new WebAPI.Hubs.UserNotificationUpdate
                {
                    NotificationId = Guid.NewGuid().ToString(),
                    Title = isSpontaneous ? "🚨 Demanda Espontânea Pronta!" : "Paciente Pronto para Consulta",
                    Message = $"{appointment.Patient.Name} {appointment.Patient.LastName} está aguardando no consultório digital",
                    Type = isSpontaneous ? "SpontaneousDemandReady" : "PatientReady",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow,
                    UnreadCount = 1,
                    Data = new Dictionary<string, object>
                    {
                        ["appointmentId"] = appointment.Id.ToString(),
                        ["meetLink"] = meetLink,
                        ["patientName"] = $"{appointment.Patient.Name} {appointment.Patient.LastName}",
                        ["specialtyName"] = appointment.Specialty.Name,
                        ["isSpontaneous"] = isSpontaneous,
                        ["urgencyColor"] = urgencyColor,
                        ["chiefComplaint"] = appointment.Observation ?? ""
                    }
                }
            );

            _logger.LogInformation("Médico {DoctorId} notificado sobre consulta {AppointmentId}", 
                appointment.ProfessionalId, appointment.Id);

            return Ok(new 
            { 
                success = true, 
                message = "Médico notificado com sucesso",
                meetLink 
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao notificar médico sobre consulta {AppointmentId}", appointmentId);
            return StatusCode(500, new { message = "Erro ao enviar notificação" });
        }
    }

    private string GetUrgencyColor(Appointment appointment)
    {
        // Se tiver urgency level na waiting list, usar aquela cor
        var waitingList = _context.WaitingLists
            .FirstOrDefault(w => w.AppointmentId == appointment.Id);

        if (waitingList?.UrgencyLevel != null)
        {
            return waitingList.UrgencyLevel switch
            {
                UrgencyLevel.Red => "#dc3545",
                UrgencyLevel.Orange => "#fd7e14",
                UrgencyLevel.Yellow => "#ffc107",
                UrgencyLevel.Green => "#28a745",
                _ => "#0d6efd"
            };
        }

        // Padrão para demanda espontânea
        return appointment.Type == AppointmentType.SpontaneousDemand ? "#dc3545" : "#0d6efd";
    }
}

// DTOs
public class CreateSpontaneousDemandDto
{
    public Guid PatientId { get; set; }
    public Guid SpecialtyId { get; set; }
    public Guid? ProfessionalId { get; set; } // Opcional - se null, escolhe automaticamente
    public UrgencyLevel UrgencyLevel { get; set; } = UrgencyLevel.Green;
    public string? ChiefComplaint { get; set; }
}
