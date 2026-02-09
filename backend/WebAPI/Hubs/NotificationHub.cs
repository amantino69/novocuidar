using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Domain.Enums;

namespace WebAPI.Hubs;

/// <summary>
/// SignalR Hub genérico para notificações em tempo real de todas as entidades do sistema
/// </summary>
public class NotificationHub : Hub
{
    private readonly ILogger<NotificationHub> _logger;
    private readonly ApplicationDbContext _context;

    public NotificationHub(ILogger<NotificationHub> logger, ApplicationDbContext context)
    {
        _logger = logger;
        _context = context;
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Cliente conectado ao NotificationHub: {ConnectionId}", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Cliente desconectado do NotificationHub: {ConnectionId}", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Inscreve o cliente para receber atualizações de um usuário específico (notificações pessoais)
    /// Também verifica se há consultas aguardando este médico
    /// </summary>
    public async Task JoinUserGroup(string userId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        _logger.LogInformation("Cliente {ConnectionId} inscrito no grupo do usuário {UserId}", Context.ConnectionId, userId);
        
        // Verificar se é um médico com consultas aguardando
        await CheckPendingConsultationsForDoctor(userId);
    }

    /// <summary>
    /// Remove a inscrição do cliente de um usuário
    /// </summary>
    public async Task LeaveUserGroup(string userId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
        _logger.LogInformation("Cliente {ConnectionId} removido do grupo do usuário {UserId}", Context.ConnectionId, userId);
    }

    /// <summary>
    /// Inscreve o cliente para receber atualizações de uma role (ADMIN, PROFESSIONAL, PATIENT)
    /// </summary>
    public async Task JoinRoleGroup(string role)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"role_{role}");
        _logger.LogInformation("Cliente {ConnectionId} inscrito no grupo da role {Role}", Context.ConnectionId, role);
    }

    /// <summary>
    /// Remove a inscrição do cliente de uma role
    /// </summary>
    public async Task LeaveRoleGroup(string role)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"role_{role}");
        _logger.LogInformation("Cliente {ConnectionId} removido do grupo da role {Role}", Context.ConnectionId, role);
    }

    /// <summary>
    /// Inscreve o cliente para receber atualizações de uma entidade específica
    /// </summary>
    public async Task JoinEntityGroup(string entityType, string entityId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"{entityType}_{entityId}");
        _logger.LogInformation("Cliente {ConnectionId} inscrito no grupo {EntityType}_{EntityId}", Context.ConnectionId, entityType, entityId);
    }

    /// <summary>
    /// Remove a inscrição do cliente de uma entidade
    /// </summary>
    public async Task LeaveEntityGroup(string entityType, string entityId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"{entityType}_{entityId}");
        _logger.LogInformation("Cliente {ConnectionId} removido do grupo {EntityType}_{EntityId}", Context.ConnectionId, entityType, entityId);
    }

    /// <summary>
    /// Verifica se há consultas aguardando o médico quando ele se conecta
    /// CAMPAINHA: Se enfermeira entrou nos últimos 20 minutos, notifica o médico
    /// </summary>
    private async Task CheckPendingConsultationsForDoctor(string userId)
    {
        try
        {
            if (!Guid.TryParse(userId, out var doctorId))
            {
                return;
            }

            // Verificar se o usuário é um médico (Professional)
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == doctorId);
            if (user == null || user.Role != UserRole.PROFESSIONAL)
            {
                return;
            }

            // CAMPAINHA: Buscar consultas deste médico com atividade recente (últimos 20 minutos)
            // Isso garante que se o médico logar dentro de 20 min após a enfermeira entrar,
            // ele receberá a notificação
            var twentyMinutesAgo = DateTime.UtcNow.AddMinutes(-20);
            var pendingConsultations = await _context.Appointments
                .Include(a => a.Patient)
                .Where(a => a.ProfessionalId == doctorId 
                         && (a.Status == AppointmentStatus.AwaitingDoctor || a.Status == AppointmentStatus.InConsultation)
                         && a.LastActivityAt != null 
                         && a.LastActivityAt > twentyMinutesAgo)
                .ToListAsync();

            _logger.LogInformation("[CAMPAINHA] Médico {DoctorId} conectou. Encontradas {Count} consultas com pacientes aguardando (últimos 20 min).", 
                userId, pendingConsultations.Count);

            foreach (var appointment in pendingConsultations)
            {
                var patientName = appointment.Patient?.Name ?? "Paciente";
                
                // Enviar notificação "campainha" para o médico
                await Clients.Caller.SendAsync("WaitingInRoom", new
                {
                    AppointmentId = appointment.Id.ToString(),
                    PatientName = patientName,
                    UserRole = "ASSISTANT",
                    Timestamp = appointment.LastActivityAt ?? appointment.UpdatedAt,
                    Message = $"🔔 {patientName} está aguardando você na sala."
                });
                
                _logger.LogInformation("[CAMPAINHA] Notificação enviada ao médico {DoctorId}: {PatientName} aguardando na consulta {AppointmentId}", 
                    userId, patientName, appointment.Id);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[CAMPAINHA] Erro ao verificar consultas pendentes para médico {UserId}: {Message}", 
                userId, ex.Message);
        }
    }
}

#region DTOs para Notificações

/// <summary>
/// Tipos de entidades que podem ser atualizadas
/// </summary>
public enum EntityType
{
    User,
    Appointment,
    Specialty,
    Schedule,
    ScheduleBlock,
    Invite,
    Notification,
    Report,
    AuditLog,
    Dashboard
}

/// <summary>
/// Tipos de operações que podem ocorrer
/// </summary>
public enum OperationType
{
    Created,
    Updated,
    Deleted,
    StatusChanged
}

/// <summary>
/// DTO base para notificações de entidades
/// </summary>
public class EntityNotification
{
    public string EntityType { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string Operation { get; set; } = string.Empty;
    public object? Data { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string? TriggeredByUserId { get; set; }
}

/// <summary>
/// DTO para atualização de dashboard/estatísticas
/// </summary>
public class DashboardUpdateNotification
{
    public string StatType { get; set; } = string.Empty; // TotalUsers, TotalAppointments, etc.
    public object? Value { get; set; }
    public object? PreviousValue { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// DTO para notificações do usuário (sino)
/// </summary>
public class UserNotificationUpdate
{
    public string NotificationId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
    public int UnreadCount { get; set; }
    public object? Data { get; set; } // Dados adicionais da notificação
}

/// <summary>
/// DTO para atualização de status de consulta
/// </summary>
public class AppointmentStatusUpdate
{
    public string AppointmentId { get; set; } = string.Empty;
    public string PreviousStatus { get; set; } = string.Empty;
    public string NewStatus { get; set; } = string.Empty;
    public string? PatientId { get; set; }
    public string? ProfessionalId { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}

#endregion
