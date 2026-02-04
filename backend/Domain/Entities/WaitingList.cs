using Domain.Common;
using Domain.Enums;

namespace Domain.Entities;

/// <summary>
/// Fila de espera - Gerencia ordem de atendimento
/// </summary>
public class WaitingList : BaseEntity
{
    public Guid AppointmentId { get; set; }
    public Guid PatientId { get; set; }
    public Guid ProfessionalId { get; set; }
    public Guid? UnityId { get; set; } // Unidade de saúde onde está aguardando
    
    // Posição na fila (1, 2, 3, etc)
    public int Position { get; set; }
    
    // Prioridade (0=Normal, 1=Preferencial, 2=Urgente)
    public int Priority { get; set; } = 0;
    
    // Nível de urgência (para demanda espontânea)
    public UrgencyLevel? UrgencyLevel { get; set; } = Domain.Enums.UrgencyLevel.Green;
    
    // Demanda espontânea (walk-in) ou agendamento regular
    public bool IsSpontaneousDemand { get; set; } = false;
    
    // Observação/Queixa principal (para demanda espontânea)
    public string? ChiefComplaint { get; set; }
    
    // Controle de chamadas
    public DateTime? CheckInTime { get; set; } // Quando a recepcionista marcou presença
    public DateTime? CalledTime { get; set; }  // Quando a enfermeira chamou
    public int CallAttempts { get; set; } = 0;  // Quantas vezes foi chamado
    
    // Status na fila
    public WaitingListStatus Status { get; set; } = WaitingListStatus.Waiting;
    
    // Navigation Properties
    public Appointment Appointment { get; set; } = null!;
    public User Patient { get; set; } = null!;
    public User Professional { get; set; } = null!;
}

/// <summary>
/// Status do paciente na fila de espera
/// </summary>
public enum WaitingListStatus
{
    Waiting,         // Aguardando na recepção
    Called,          // Foi chamado pela enfermeira
    InConsultation,  // Entrou no consultório digital
    Completed,       // Atendimento finalizado
    NoShow           // Não compareceu após ser chamado
}
