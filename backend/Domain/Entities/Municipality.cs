using Domain.Common;

namespace Domain.Entities;

/// <summary>
/// Município cadastrado no sistema TeleCuidar
/// Utiliza código IBGE como identificador único
/// </summary>
public class Municipality : BaseEntity
{
    /// <summary>
    /// Código IBGE do município (7 dígitos)
    /// Ex: 3550308 = São Paulo/SP
    /// </summary>
    public string CodigoIBGE { get; set; } = string.Empty;
    
    /// <summary>
    /// Nome do município
    /// </summary>
    public string Nome { get; set; } = string.Empty;
    
    /// <summary>
    /// Sigla do estado (UF)
    /// </summary>
    public string UF { get; set; } = string.Empty;
    
    /// <summary>
    /// Indica se o município está ativo no sistema (aderiu ao TeleCuidar)
    /// </summary>
    public bool Ativo { get; set; } = true;
    
    /// <summary>
    /// Data de adesão ao TeleCuidar
    /// </summary>
    public DateTime? DataAdesao { get; set; }
    
    // Navigation Properties
    
    /// <summary>
    /// Estabelecimentos de saúde do município
    /// </summary>
    public ICollection<HealthFacility> HealthFacilities { get; set; } = new List<HealthFacility>();
    
    /// <summary>
    /// Pacientes vinculados ao município
    /// </summary>
    public ICollection<PatientProfile> Patients { get; set; } = new List<PatientProfile>();
    
    /// <summary>
    /// Reguladores (usuários) vinculados ao município
    /// </summary>
    public ICollection<User> Reguladores { get; set; } = new List<User>();
}
