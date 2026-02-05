namespace Domain.Enums;

public enum AppointmentStatus
{
    Scheduled,      // Agendada
    Confirmed,      // Confirmada
    CheckedIn,      // Recepcionista marcou presença (NOVO)
    InProgress,     // Enfermeira abriu atendimento
    InConsultation, // Médico entrou na consulta (NOVO)
    Completed,      // Encerrada
    Cancelled,      // Cancelada
    NoShow,         // Paciente não compareceu (NOVO)
    Abandoned       // Consulta abandonada por inatividade (TIMEOUT - NOVO)
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
