using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Domain.Enums;

namespace WebAPI.Hubs;

/// <summary>
/// SignalR Hub específico para teleconsultas em tempo real
/// Permite sincronização de dados entre paciente e profissional durante a consulta
/// </summary>
public class TeleconsultationHub : Hub
{
    private readonly ILogger<TeleconsultationHub> _logger;
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<NotificationHub> _notificationHub;

    public TeleconsultationHub(
        ILogger<TeleconsultationHub> logger, 
        ApplicationDbContext context,
        IHubContext<NotificationHub> notificationHub)
    {
        _logger = logger;
        _context = context;
        _notificationHub = notificationHub;
    }

    public override async Task OnConnectedAsync()
    {
        _logger.LogInformation("Cliente conectado ao TeleconsultationHub: {ConnectionId}", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("Cliente desconectado do TeleconsultationHub: {ConnectionId}", Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Entra na sala da teleconsulta (appointment)
    /// Também atualiza o status para InProgress se estiver Scheduled/Confirmed/Abandoned (reconexão automática)
    /// E notifica o médico se for paciente/enfermeira entrando
    /// Atualiza LastActivityAt para rastrear timeout
    /// </summary>
    public async Task JoinConsultation(string appointmentId, string? userRole = null, string? userName = null)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"consultation_{appointmentId}");
        _logger.LogInformation("Cliente {ConnectionId} entrou na consulta {AppointmentId} (Role: {Role})", 
            Context.ConnectionId, appointmentId, userRole ?? "unknown");
        
        // Atualizar status para InProgress se a consulta existir e não estiver finalizada
        if (Guid.TryParse(appointmentId, out var id))
        {
            var appointment = await _context.Appointments
                .Include(a => a.Professional)
                .Include(a => a.Patient)
                .FirstOrDefaultAsync(a => a.Id == id);
                
            if (appointment != null)
            {
                var statusChanged = false;
                var now = DateTime.UtcNow;
                
                // Reconexão automática: Se foi abandonada, voltar para InProgress
                if (appointment.Status == AppointmentStatus.Abandoned)
                {
                    appointment.Status = AppointmentStatus.InProgress;
                    statusChanged = true;
                    _logger.LogInformation("[Timeout] Reconexão automática - Consulta {AppointmentId} voltou de Abandoned para InProgress", appointmentId);
                }
                // Atualizar status se necessário
                else if (appointment.Status == AppointmentStatus.Scheduled || 
                    appointment.Status == AppointmentStatus.Confirmed)
                {
                    appointment.Status = AppointmentStatus.InProgress;
                    statusChanged = true;
                    _logger.LogInformation("[Teleconsulta] Status atualizado para InProgress: {AppointmentId}", appointmentId);
                }
                
                // Atualizar LastActivityAt para rastrear timeout
                appointment.LastActivityAt = now;
                appointment.UpdatedAt = now;
                await _context.SaveChangesAsync();
                
                // Se NÃO for o médico entrando, notificar o médico que tem alguém aguardando
                // appointment.Professional é do tipo User (não ProfessionalProfile)
                if (userRole != null && userRole != "PROFESSIONAL" && appointment.Professional != null)
                {
                    var patientName = userName ?? appointment.Patient?.Name ?? "Paciente";
                    
                    // Enviar notificação ao médico via NotificationHub
                    await _notificationHub.Clients
                        .Group($"user_{appointment.Professional.Id}")
                        .SendAsync("WaitingInRoom", new
                        {
                            AppointmentId = appointmentId,
                            PatientName = patientName,
                            UserRole = userRole,
                            Timestamp = now
                        });
                    
                    _logger.LogInformation("[Teleconsulta] Notificação WaitingInRoom enviada ao médico {DoctorId} para consulta {AppointmentId}", 
                        appointment.Professional.Id, appointmentId);
                }
            }
        }
        
        // Notificar outros participantes
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("ParticipantJoined", new
        {
            ConnectionId = Context.ConnectionId,
            UserRole = userRole,
            UserName = userName,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Sai da sala da teleconsulta
    /// </summary>
    public async Task LeaveConsultation(string appointmentId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"consultation_{appointmentId}");
        _logger.LogInformation("Cliente {ConnectionId} saiu da consulta {AppointmentId}", Context.ConnectionId, appointmentId);
        
        // Notificar outros participantes
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("ParticipantLeft", new
        {
            ConnectionId = Context.ConnectionId,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Notifica que dados foram atualizados (SOAP, Anamnese, etc)
    /// </summary>
    public async Task NotifyDataUpdated(string appointmentId, string dataType, object? data = null)
    {
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("DataUpdated", new
        {
            DataType = dataType,
            Data = data,
            Timestamp = DateTime.UtcNow
        });
        _logger.LogInformation("Dados {DataType} atualizados na consulta {AppointmentId}", dataType, appointmentId);
    }

    /// <summary>
    /// Notifica que um novo anexo foi adicionado
    /// </summary>
    public async Task NotifyAttachmentAdded(string appointmentId, object attachment)
    {
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("AttachmentAdded", new
        {
            Attachment = attachment,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Notifica que um anexo foi removido
    /// </summary>
    public async Task NotifyAttachmentRemoved(string appointmentId, string attachmentId)
    {
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("AttachmentRemoved", new
        {
            AttachmentId = attachmentId,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Notifica que a receita foi atualizada
    /// </summary>
    public async Task NotifyPrescriptionUpdated(string appointmentId, object? prescription = null)
    {
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("PrescriptionUpdated", new
        {
            Prescription = prescription,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Notifica mudança de status da consulta
    /// </summary>
    public async Task NotifyStatusChanged(string appointmentId, string newStatus)
    {
        await Clients.Group($"consultation_{appointmentId}").SendAsync("StatusChanged", new
        {
            Status = newStatus,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Envia notificação de digitação (para chat)
    /// </summary>
    public async Task SendTypingIndicator(string appointmentId, bool isTyping)
    {
        await Clients.OthersInGroup($"consultation_{appointmentId}").SendAsync("TypingIndicator", new
        {
            ConnectionId = Context.ConnectionId,
            IsTyping = isTyping,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Envia uma mensagem de chat
    /// </summary>
    public async Task SendChatMessage(string appointmentId, string message, string senderRole)
    {
        await Clients.Group($"consultation_{appointmentId}").SendAsync("ChatMessage", new
        {
            Message = message,
            SenderRole = senderRole,
            ConnectionId = Context.ConnectionId,
            Timestamp = DateTime.UtcNow
        });
    }

    /// <summary>
    /// Registra um token de upload mobile para receber notificações
    /// </summary>
    public async Task RegisterMobileUploadToken(string token)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"mobile_upload_{token}");
        _logger.LogInformation("Cliente {ConnectionId} registrado para uploads com token {Token}", Context.ConnectionId, token);
    }

    /// <summary>
    /// Remove registro do token de upload mobile
    /// </summary>
    public async Task UnregisterMobileUploadToken(string token)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"mobile_upload_{token}");
        _logger.LogInformation("Cliente {ConnectionId} removido de uploads com token {Token}", Context.ConnectionId, token);
    }

    // ========== FONOCARDIOGRAMA EM TEMPO REAL ==========

    /// <summary>
    /// Envia frame de fonocardiograma para outros participantes da consulta
    /// Frame contém: waveform (64 pontos), heartRate, s1Amplitude, s2Amplitude
    /// Transmissão leve (~200 bytes por frame, 60fps = ~12KB/s)
    /// </summary>
    public async Task SendPhonocardiogramFrame(string appointmentId, object frame)
    {
        // Enviar para todos exceto o remetente (médico recebe do paciente)
        await Clients.OthersInGroup($"consultation_{appointmentId}")
            .SendAsync("ReceivePhonocardiogramFrame", frame);
    }

    // ========== TIMEOUT E RECONEXÃO ==========

    /// <summary>
    /// Chamado periodicamente (a cada 2 minutos) pelo frontend para manter consulta ativa
    /// Atualiza LastActivityAt sem que o usuário precise fazer re-join
    /// Impede que a consulta seja marcada como Abandoned pelo background job
    /// </summary>
    public async Task UpdateActivity(string appointmentId)
    {
        if (!Guid.TryParse(appointmentId, out var id))
        {
            _logger.LogWarning("[Timeout] UpdateActivity com appointmentId inválido: {AppointmentId}", appointmentId);
            return;
        }

        try
        {
            var appointment = await _context.Appointments
                .FirstOrDefaultAsync(a => a.Id == id);

            if (appointment == null)
            {
                _logger.LogWarning("[Timeout] UpdateActivity: Consulta {AppointmentId} não encontrada", appointmentId);
                return;
            }

            // Atualizar LastActivityAt
            var now = DateTime.UtcNow;
            appointment.LastActivityAt = now;
            appointment.UpdatedAt = now;
            await _context.SaveChangesAsync();

            _logger.LogDebug("[Timeout] UpdateActivity: LastActivityAt atualizado para consulta {AppointmentId}", appointmentId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Timeout] Erro ao atualizar atividade da consulta {AppointmentId}: {Message}", 
                appointmentId, ex.Message);
        }
    }
}
