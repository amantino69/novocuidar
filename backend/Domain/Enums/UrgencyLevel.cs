namespace Domain.Enums;

/// <summary>
/// Nível de urgência para triagem de demanda espontânea
/// </summary>
public enum UrgencyLevel
{
    Green = 0,   // Baixa urgência - até 2 horas
    Yellow = 1,  // Média urgência - até 1 hora
    Orange = 2,  // Alta urgência - até 30 min
    Red = 3      // Urgência crítica - imediato
}
