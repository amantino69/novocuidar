using Domain.Common;

namespace Domain.Entities;

/// <summary>
/// Estabelecimento de Saúde cadastrado no sistema TeleCuidar
/// Dados importados do CNES (Cadastro Nacional de Estabelecimentos de Saúde)
/// </summary>
public class HealthFacility : BaseEntity
{
    /// <summary>
    /// Código CNES do estabelecimento (7 dígitos)
    /// Identificador único no sistema de saúde nacional
    /// </summary>
    public string CodigoCNES { get; set; } = string.Empty;
    
    /// <summary>
    /// Nome fantasia do estabelecimento
    /// </summary>
    public string NomeFantasia { get; set; } = string.Empty;
    
    /// <summary>
    /// Razão social do estabelecimento
    /// </summary>
    public string? RazaoSocial { get; set; }
    
    /// <summary>
    /// Tipo de estabelecimento (UBS, UPA, Hospital, etc.)
    /// Código da tabela do CNES
    /// </summary>
    public string? TipoEstabelecimento { get; set; }
    
    /// <summary>
    /// Descrição do tipo de estabelecimento
    /// </summary>
    public string? TipoEstabelecimentoDescricao { get; set; }
    
    /// <summary>
    /// CNPJ do estabelecimento
    /// </summary>
    public string? CNPJ { get; set; }
    
    /// <summary>
    /// CEP do endereço
    /// </summary>
    public string? CEP { get; set; }
    
    /// <summary>
    /// Logradouro (rua, avenida, etc.)
    /// </summary>
    public string? Logradouro { get; set; }
    
    /// <summary>
    /// Número do endereço
    /// </summary>
    public string? Numero { get; set; }
    
    /// <summary>
    /// Complemento do endereço
    /// </summary>
    public string? Complemento { get; set; }
    
    /// <summary>
    /// Bairro
    /// </summary>
    public string? Bairro { get; set; }
    
    /// <summary>
    /// Telefone de contato
    /// </summary>
    public string? Telefone { get; set; }
    
    /// <summary>
    /// Email de contato
    /// </summary>
    public string? Email { get; set; }
    
    /// <summary>
    /// Latitude para geolocalização
    /// </summary>
    public double? Latitude { get; set; }
    
    /// <summary>
    /// Longitude para geolocalização
    /// </summary>
    public double? Longitude { get; set; }
    
    /// <summary>
    /// Indica se o estabelecimento possui consultório digital TeleCuidar instalado
    /// </summary>
    public bool TemConsultorioDigital { get; set; } = false;
    
    /// <summary>
    /// Indica se o estabelecimento está ativo
    /// </summary>
    public bool Ativo { get; set; } = true;
    
    /// <summary>
    /// Data da última sincronização com CNES
    /// </summary>
    public DateTime? UltimaSincronizacaoCNES { get; set; }
    
    // Foreign Keys
    
    /// <summary>
    /// ID do município (FK)
    /// </summary>
    public Guid MunicipioId { get; set; }
    
    // Navigation Properties
    
    /// <summary>
    /// Município ao qual pertence o estabelecimento
    /// </summary>
    public Municipality Municipio { get; set; } = null!;
    
    /// <summary>
    /// Pacientes adscritos a este estabelecimento
    /// </summary>
    public ICollection<PatientProfile> PacientesAdscritos { get; set; } = new List<PatientProfile>();
}
