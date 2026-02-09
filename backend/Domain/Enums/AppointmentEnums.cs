namespace Domain.Enums;

/// <summary>
/// Estados possíveis de uma consulta médica
/// Fluxo: Scheduled → Confirmed → CheckedIn → AwaitingDoctor → InConsultation → Completed
/// Alternativos: Cancelled, NoShow, PendingClosure
/// </summary>
public enum AppointmentStatus
{
    /// <summary>Consulta agendada, aguardando confirmação do paciente</summary>
    Scheduled,
    
    /// <summary>Paciente confirmou presença</summary>
    Confirmed,
    
    /// <summary>Recepcionista registrou chegada do paciente ao polo</summary>
    CheckedIn,
    
    /// <summary>Sala preparada, aguardando médico entrar (enfermeira abriu)</summary>
    AwaitingDoctor,
    
    /// <summary>Médico e paciente em atendimento ativo</summary>
    InConsultation,
    
    /// <summary>Médico saiu sem finalizar - pode retomar em até 24h</summary>
    PendingClosure,
    
    /// <summary>Consulta finalizada formalmente pelo médico</summary>
    Completed,
    
    /// <summary>Cancelada antes de iniciar</summary>
    Cancelled,
    
    /// <summary>Paciente não compareceu no dia agendado</summary>
    NoShow,
    
    // ======= LEGADO (mantido para compatibilidade com dados existentes) =======
    /// <summary>[LEGADO] Use AwaitingDoctor. Mantido para migração.</summary>
    [Obsolete("Use AwaitingDoctor. Este valor será removido em versão futura.")]
    InProgress = 100,
    
    /// <summary>[LEGADO] Use PendingClosure. Mantido para migração.</summary>
    [Obsolete("Use PendingClosure. Este valor será removido em versão futura.")]
    Abandoned = 101
}

public enum AppointmentType
{
    FirstVisit,
    Return,
    Routine,
    Emergency,
    Common,
    Referral,
    SpontaneousDemand
}
