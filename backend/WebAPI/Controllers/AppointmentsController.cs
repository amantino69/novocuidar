using Application.DTOs.Appointments;
using Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using WebAPI.Extensions;
using WebAPI.Services;
using WebAPI.Hubs;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Domain.Enums;

namespace WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AppointmentsController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;
    private readonly IAuditLogService _auditLogService;
    private readonly ISchedulingNotificationService _schedulingNotificationService;
    private readonly IRealTimeNotificationService _realTimeNotification;
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<NotificationHub> _notificationHub;

    public AppointmentsController(
        IAppointmentService appointmentService, 
        IAuditLogService auditLogService,
        ISchedulingNotificationService schedulingNotificationService,
        IRealTimeNotificationService realTimeNotification,
        ApplicationDbContext context,
        IHubContext<NotificationHub> notificationHub)
    {
        _appointmentService = appointmentService;
        _auditLogService = auditLogService;
        _schedulingNotificationService = schedulingNotificationService;
        _realTimeNotification = realTimeNotification;
        _context = context;
        _notificationHub = notificationHub;
    }
    
    private Guid? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return userIdClaim != null ? Guid.Parse(userIdClaim) : null;
    }

    [HttpGet]
    public async Task<ActionResult<PaginatedAppointmentsDto>> GetAppointments(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] Guid? patientId = null,
        [FromQuery] Guid? professionalId = null,
        [FromQuery] string? professionalName = null,
        [FromQuery] string? patientName = null)
    {
        var currentUserId = GetCurrentUserId();
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Se o usuário é PATIENT, forçar filtro por patientId
        if (userRole == "PATIENT" && currentUserId.HasValue)
        {
            patientId = currentUserId.Value;
        }
        // Se o usuário é PROFESSIONAL, forçar filtro por professionalId
        else if (userRole == "PROFESSIONAL" && currentUserId.HasValue)
        {
            professionalId = currentUserId.Value;
        }
        // ADMIN e ASSISTANT podem ver todas as consultas (não aplica filtro)

        var result = await _appointmentService.GetAppointmentsAsync(page, pageSize, search, status, startDate, endDate, patientId, professionalId, professionalName, patientName);
        return Ok(result);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<AppointmentDto>> GetAppointment(Guid id)
    {
        var appointment = await _appointmentService.GetAppointmentByIdAsync(id);
        if (appointment == null)
            return NotFound();

        return Ok(appointment);
    }

    [HttpPost]
    public async Task<ActionResult<AppointmentDto>> CreateAppointment([FromBody] CreateAppointmentDto dto)
    {
        try
        {
            var appointment = await _appointmentService.CreateAppointmentAsync(dto);
            
            // Obter connectionId do SignalR do usuário atual (se conectado)
            var currentUserId = GetCurrentUserId()?.ToString();
            
            // Notificar em tempo real sobre o slot ocupado (excluindo o usuário que criou)
            await _schedulingNotificationService.NotifyAppointmentCreatedAsync(
                appointment.ProfessionalId.ToString(),
                appointment.SpecialtyId.ToString(),
                appointment.Date,
                appointment.Time,
                appointment.Id.ToString(),
                currentUserId
            );
            
            // Real-time notification for dashboard and lists
            await _realTimeNotification.NotifyEntityCreatedAsync("Appointment", appointment.Id.ToString(), appointment, currentUserId);
            await _realTimeNotification.NotifyDashboardUpdateAsync(new DashboardUpdateNotification
            {
                StatType = "TotalAppointments",
                Value = null
            });
            
            // Notificar o profissional via SignalR (sino de notificações)
            // A notificação já foi criada no AppointmentService, então buscamos a contagem atualizada
            var patientName = appointment.PatientName ?? "Paciente";
            var dateInfo = appointment.Date.ToString("dd/MM/yyyy") + " às " + appointment.Time;
            
            // Buscar contagem de não lidas do profissional para enviar no SignalR
            // O ID da notificação não é crítico para o SignalR - o frontend vai recarregar a lista
            await _realTimeNotification.NotifyUserAsync(appointment.ProfessionalId.ToString(), new UserNotificationUpdate
            {
                NotificationId = appointment.Id.ToString(), // Usar ID do appointment como referência
                Title = "📅 Nova Consulta Agendada",
                Message = $"Uma consulta foi agendada com {patientName} para {dateInfo}",
                Type = "Info",
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                UnreadCount = 0 // Frontend vai buscar contagem real via API
            });
            
            // Audit log
            await _auditLogService.CreateAuditLogAsync(
                GetCurrentUserId(),
                "create",
                "Appointment",
                appointment.Id.ToString(),
                null,
                HttpContextExtensions.SerializeToJson(new { appointment.PatientId, appointment.ProfessionalId, appointment.Date, appointment.Time, appointment.Status }),
                HttpContext.GetIpAddress(),
                HttpContext.GetUserAgent()
            );
            
            return CreatedAtAction(nameof(GetAppointment), new { id = appointment.Id }, appointment);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("{id}")]
    public async Task<ActionResult<AppointmentDto>> UpdateAppointment(Guid id, [FromBody] UpdateAppointmentDto dto)
    {
        var oldAppointment = await _appointmentService.GetAppointmentByIdAsync(id);
        if (oldAppointment == null)
            return NotFound();
        
        var appointment = await _appointmentService.UpdateAppointmentAsync(id, dto);
        
        // Audit log with differences
        var oldValues = oldAppointment != null ? HttpContextExtensions.SerializeToJson(new { oldAppointment.Date, oldAppointment.Time, oldAppointment.Status, oldAppointment.Observation }) : null;
        var newValues = HttpContextExtensions.SerializeToJson(new { appointment?.Date, appointment?.Time, appointment?.Status, appointment?.Observation });
        
        await _auditLogService.CreateAuditLogAsync(
            GetCurrentUserId(),
            "update",
            "Appointment",
            id.ToString(),
            oldValues,
            newValues,
            HttpContext.GetIpAddress(),
            HttpContext.GetUserAgent()
        );
        
        // Real-time notification for status changes
        if (appointment != null && oldAppointment != null && oldAppointment.Status != appointment.Status)
        {
            await _realTimeNotification.NotifyAppointmentStatusChangeAsync(new AppointmentStatusUpdate
            {
                AppointmentId = id.ToString(),
                PreviousStatus = oldAppointment.Status,
                NewStatus = appointment.Status,
                PatientId = appointment.PatientId.ToString(),
                ProfessionalId = appointment.ProfessionalId.ToString()
            });
        }
        
        await _realTimeNotification.NotifyEntityUpdatedAsync("Appointment", id.ToString(), appointment!, GetCurrentUserId()?.ToString());

        return Ok(appointment);
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult> CancelAppointment(Guid id)
    {
        var appointment = await _appointmentService.GetAppointmentByIdAsync(id);
        if (appointment == null)
            return NotFound();
        
        var result = await _appointmentService.CancelAppointmentAsync(id);
        
        // Notificar em tempo real sobre o slot liberado
        await _schedulingNotificationService.NotifyAppointmentCancelledAsync(
            appointment.ProfessionalId.ToString(),
            appointment.SpecialtyId.ToString(),
            appointment.Date,
            appointment.Time,
            id.ToString()
        );
        
        // Real-time notification for status change
        await _realTimeNotification.NotifyAppointmentStatusChangeAsync(new AppointmentStatusUpdate
        {
            AppointmentId = id.ToString(),
            PreviousStatus = appointment.Status,
            NewStatus = "Cancelled",
            PatientId = appointment.PatientId.ToString(),
            ProfessionalId = appointment.ProfessionalId.ToString()
        });
        await _realTimeNotification.NotifyDashboardUpdateAsync(new DashboardUpdateNotification
        {
            StatType = "AppointmentCancelled",
            Value = null
        });
        
        // Audit log
        await _auditLogService.CreateAuditLogAsync(
            GetCurrentUserId(),
            "update",
            "Appointment",
            id.ToString(),
            HttpContextExtensions.SerializeToJson(new { Status = appointment.Status }),
            HttpContextExtensions.SerializeToJson(new { Status = "CANCELLED" }),
            HttpContext.GetIpAddress(),
            HttpContext.GetUserAgent()
        );

        return Ok(new { message = "Appointment cancelled successfully" });
    }

    [HttpPost("{id}/finish")]
    public async Task<ActionResult> FinishAppointment(Guid id)
    {
        var appointment = await _appointmentService.GetAppointmentByIdAsync(id);
        if (appointment == null)
            return NotFound();
        
        var result = await _appointmentService.FinishAppointmentAsync(id);
        
        // Real-time notification for status change
        await _realTimeNotification.NotifyAppointmentStatusChangeAsync(new AppointmentStatusUpdate
        {
            AppointmentId = id.ToString(),
            PreviousStatus = appointment.Status,
            NewStatus = "Finished",
            PatientId = appointment.PatientId.ToString(),
            ProfessionalId = appointment.ProfessionalId.ToString()
        });
        await _realTimeNotification.NotifyDashboardUpdateAsync(new DashboardUpdateNotification
        {
            StatType = "AppointmentCompleted",
            Value = null
        });
        
        // Audit log
        await _auditLogService.CreateAuditLogAsync(
            GetCurrentUserId(),
            "update",
            "Appointment",
            id.ToString(),
            HttpContextExtensions.SerializeToJson(new { Status = appointment.Status }),
            HttpContextExtensions.SerializeToJson(new { Status = "FINISHED" }),
            HttpContext.GetIpAddress(),
            HttpContext.GetUserAgent()
        );

        return Ok(new { message = "Appointment finished successfully" });
    }

    /// <summary>
    /// Busca consultas de um paciente por CPF ou nome (para médicos visualizarem histórico)
    /// Filtra apenas consultas do profissional logado
    /// </summary>
    [HttpGet("search-by-patient")]
    [Authorize(Roles = "PROFESSIONAL,ADMIN")]
    public async Task<ActionResult<IEnumerable<AppointmentDto>>> SearchByPatient(
        [FromQuery] string search,
        [FromQuery] string sortOrder = "desc")
    {
        if (string.IsNullOrWhiteSpace(search))
            return BadRequest(new { message = "Termo de busca é obrigatório" });

        var professionalId = GetCurrentUserId();
        if (professionalId == null)
            return Unauthorized(new { message = "Usuário não identificado" });

        var appointments = await _appointmentService.SearchByPatientAsync(search, sortOrder, professionalId.Value);
        return Ok(appointments);
    }
    
    /// <summary>
    /// Inicia atendimento - Enfermeira marca que paciente entrou no consultório digital
    /// DISPARA NOTIFICAÇÃO PARA O MÉDICO
    /// </summary>
    [HttpPost("{id}/start-consultation")]
    [Authorize(Roles = "ASSISTANT,ADMIN")]
    public async Task<IActionResult> StartConsultation(Guid id)
    {
        var appointment = await _context.Appointments
            .Include(a => a.Patient)
                .ThenInclude(p => p.PatientProfile)
            .Include(a => a.Professional)
            .Include(a => a.Specialty)
            .FirstOrDefaultAsync(a => a.Id == id);
            
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        if (appointment.Status != AppointmentStatus.CheckedIn && 
            appointment.Status != AppointmentStatus.Scheduled && 
            appointment.Status != AppointmentStatus.Confirmed)
            return BadRequest(new { message = $"Consulta não pode ser iniciada. Status atual: {appointment.Status}" });

        var assistantId = GetCurrentUserId();
        if (assistantId == null)
            return Unauthorized(new { message = "Usuário não identificado" });

        // Atualizar appointment
        appointment.Status = AppointmentStatus.InProgress;
        appointment.ConsultationStartedAt = DateTime.UtcNow;
        appointment.AssistantId = assistantId.Value;
        appointment.NotificationsSentCount++;
        appointment.LastNotificationSentAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Calcular tempo de espera
        var waitingTime = appointment.CheckInTime.HasValue 
            ? (DateTime.UtcNow - appointment.CheckInTime.Value).TotalMinutes 
            : 0;
        
        // Calcular idade do paciente
        var patientAge = appointment.Patient.PatientProfile?.BirthDate != null
            ? DateTime.UtcNow.Year - appointment.Patient.PatientProfile.BirthDate.Value.Year
            : 0;

        // Preparar dados para notificação
        var notificationData = new
        {
            AppointmentId = appointment.Id,
            PatientName = appointment.Patient.Name + " " + appointment.Patient.LastName,
            PatientAge = patientAge,
            Specialty = appointment.Specialty.Name,
            AssistantName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Assistente",
            WaitingTime = Math.Round(waitingTime, 0),
            MeetLink = appointment.MeetLink
        };

        // 🔔 ENVIAR NOTIFICAÇÃO PARA O MÉDICO via SignalR
        await _realTimeNotification.NotifyUserAsync(
            appointment.ProfessionalId.ToString(),
            new WebAPI.Hubs.UserNotificationUpdate
            {
                NotificationId = Guid.NewGuid().ToString(),
                Title = "Paciente Aguardando",
                Message = $"{appointment.Patient.Name} {appointment.Patient.LastName} está pronto para consulta",
                Type = "PatientWaiting",
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                UnreadCount = 1,
                Data = new {
                    AppointmentId = appointment.Id.ToString(),
                    PatientName = appointment.Patient.Name + " " + appointment.Patient.LastName,
                    PatientAge = patientAge,
                    Specialty = appointment.Specialty.Name,
                    MeetLink = appointment.MeetLink
                }
            }
        );

        // Audit log
        await _auditLogService.CreateAuditLogAsync(
            assistantId,
            "start_consultation",
            "Appointment",
            id.ToString(),
            HttpContextExtensions.SerializeToJson(new { Status = appointment.Status }),
            HttpContextExtensions.SerializeToJson(new { Status = "InProgress", ConsultationStartedAt = appointment.ConsultationStartedAt }),
            HttpContext.GetIpAddress(),
            HttpContext.GetUserAgent()
        );

        return Ok(new
        {
            Success = true,
            Message = "Atendimento iniciado. Médico foi notificado.",
            NotificationSent = true
        });
    }

    /// <summary>
    /// 🔔 CAMPAINHA - Enfermeira chama o médico
    /// Envia notificação visual e sonora ao médico, independente do status da consulta
    /// </summary>
    [HttpPost("{id}/call-doctor")]
    [Authorize(Roles = "ASSISTANT,ADMIN,PATIENT")]
    public async Task<IActionResult> CallDoctor(Guid id)
    {
        var appointment = await _context.Appointments
            .Include(a => a.Patient)
            .Include(a => a.Professional)
            .FirstOrDefaultAsync(a => a.Id == id);
            
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        if (appointment.Professional == null)
            return BadRequest(new { message = "Consulta sem médico associado" });

        var callerName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Equipe";
        var patientName = appointment.Patient?.Name ?? "Paciente";

        // Atualizar LastActivityAt para que o médico receba a notificação se logar depois
        appointment.LastActivityAt = DateTime.UtcNow;
        appointment.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // 🔔 Enviar evento WaitingInRoom diretamente ao médico via SignalR
        // O frontend escuta este evento para destacar o botão "Entrar na Consulta"
        await _notificationHub.Clients.Group($"user_{appointment.ProfessionalId}")
            .SendAsync("WaitingInRoom", new {
                AppointmentId = appointment.Id.ToString(),
                PatientName = patientName,
                UserRole = "ASSISTANT",
                Timestamp = DateTime.UtcNow
            });

        return Ok(new { Success = true, Message = "Médico notificado!" });
    }
    
    /// <summary>
    /// Médico confirma que entrou na consulta
    /// </summary>
    [HttpPost("{id}/doctor-joined")]
    [Authorize(Roles = "PROFESSIONAL")]
    public async Task<IActionResult> DoctorJoined(Guid id)
    {
        var appointment = await _context.Appointments
            .Include(a => a.Patient)
            .FirstOrDefaultAsync(a => a.Id == id);
            
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        var professionalId = GetCurrentUserId();
        if (appointment.ProfessionalId != professionalId)
            return Forbid();

        appointment.Status = AppointmentStatus.InConsultation;
        appointment.DoctorJoinedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Notificar enfermeira que médico entrou
        if (appointment.AssistantId.HasValue)
        {
            await _realTimeNotification.NotifyUserAsync(
                appointment.AssistantId.Value.ToString(),
                new WebAPI.Hubs.UserNotificationUpdate
                {
                    NotificationId = Guid.NewGuid().ToString(),
                    Title = "Médico Entrou",
                    Message = $"Médico entrou na consulta com {appointment.Patient.Name}",
                    Type = "DoctorJoined",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow,
                    UnreadCount = 1
                }
            );
        }

        return Ok(new { Success = true, Message = "Médico entrou na consulta" });
    }
    
    /// <summary>
    /// Retorna consultas aguardando o médico (status InProgress, médico ainda não entrou)
    /// Usado para polling no painel do médico
    /// </summary>
    [HttpGet("waiting-for-doctor")]
    [Authorize(Roles = "PROFESSIONAL")]
    public async Task<IActionResult> GetWaitingForDoctor()
    {
        var professionalId = GetCurrentUserId();
        if (professionalId == null)
            return Unauthorized(new { message = "Usuário não identificado" });

        var waitingConsultations = await _context.Appointments
            .Include(a => a.Patient)
                .ThenInclude(p => p.PatientProfile)
            .Include(a => a.Specialty)
            .Where(a => a.ProfessionalId == professionalId.Value)
            .Where(a => a.Status == AppointmentStatus.InProgress)
            .Where(a => a.DoctorJoinedAt == null) // Médico ainda não entrou
            .OrderBy(a => a.ConsultationStartedAt)
            .Select(a => new
            {
                a.Id,
                PatientName = a.Patient.Name + " " + a.Patient.LastName,
                PatientBirthDate = a.Patient.PatientProfile != null ? a.Patient.PatientProfile.BirthDate : (DateTime?)null,
                PatientSex = a.Patient.PatientProfile != null ? a.Patient.PatientProfile.Gender : null,
                PatientAvatar = a.Patient.Avatar,
                SpecialtyName = a.Specialty != null ? a.Specialty.Name : "Clínica Geral",
                a.ConsultationStartedAt,
                WaitingMinutes = a.ConsultationStartedAt.HasValue 
                    ? (int)(DateTime.UtcNow - a.ConsultationStartedAt.Value).TotalMinutes 
                    : 0,
                a.MeetLink,
                a.Type
            })
            .ToListAsync();

        return Ok(waitingConsultations);
    }
}

