using Domain.Common;
using Domain.Enums;

namespace Domain.Entities;

public class Appointment : BaseEntity
{
    public Guid PatientId { get; set; }
    public Guid ProfessionalId { get; set; }
    public Guid SpecialtyId { get; set; }
    
    // Informações de agendamento
    public DateTime Date { get; set; }
    public TimeSpan Time { get; set; }
    public TimeSpan? EndTime { get; set; }
    public AppointmentType Type { get; set; }
    public AppointmentStatus Status { get; set; }
    public string? Observation { get; set; }
    public string? MeetLink { get; set; }
    
    // Controle de atendimento (NOVOS)
    public Guid? AssistantId { get; set; } // Enfermeira que está apoiando
    public DateTime? CheckInTime { get; set; } // Quando recepcionista marcou presença
    public DateTime? ConsultationStartedAt { get; set; } // Quando enfermeira abriu
    public DateTime? DoctorJoinedAt { get; set; } // Quando médico entrou
    public DateTime? ConsultationEndedAt { get; set; } // Quando foi encerrada
    public int? DurationInMinutes { get; set; } // Duração total
    public int NotificationsSentCount { get; set; } = 0; // Quantas notificações enviadas ao médico
    public DateTime? LastNotificationSentAt { get; set; } // Última notificação enviada
    public string? PreConsultationJson { get; set; } // Store PreConsultationForm as JSON
    public string? BiometricsJson { get; set; } // Store BiometricsData as JSON
    public string? AttachmentsChatJson { get; set; } // Store AttachmentMessage[] as JSON
    
    // Clinical Data
    public string? AnamnesisJson { get; set; } // Store Anamnesis data as JSON
    public string? SoapJson { get; set; } // Store SOAP notes as JSON
    public string? SpecialtyFieldsJson { get; set; } // Store specialty-specific fields as JSON
    
    // AI Generated Data
    public string? AISummary { get; set; } // AI-generated summary of the consultation
    public DateTime? AISummaryGeneratedAt { get; set; }
    public string? AIDiagnosticHypothesis { get; set; } // AI-generated diagnostic hypothesis
    public DateTime? AIDiagnosisGeneratedAt { get; set; }
    
    // Navigation Properties
    public User Patient { get; set; } = null!;
    public User Professional { get; set; } = null!;
    public User? Assistant { get; set; } // Enfermeira que apoiou (NOVO)
    public Specialty Specialty { get; set; } = null!;
    public ICollection<Attachment> Attachments { get; set; } = new List<Attachment>();
    public WaitingList? WaitingList { get; set; } // Posição na fila (NOVO)
}
