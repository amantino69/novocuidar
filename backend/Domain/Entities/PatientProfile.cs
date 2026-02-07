using Domain.Common;

namespace Domain.Entities;

/// <summary>
/// Perfil específico para usuários do tipo PATIENT
/// Relacionamento 1:1 com User
/// </summary>
public class PatientProfile : BaseEntity
{
    // Referência ao usuário
    public Guid UserId { get; set; }
    
    // Dados de identificação
    public string? Cns { get; set; } // Cartão Nacional de Saúde
    public string? SocialName { get; set; } // Nome Social
    public string? ESusId { get; set; } // ID do e-SUS (identificador no sistema do município)
    
    // Dados pessoais
    public string? Gender { get; set; } // Sexo (M, F, Outro)
    public DateTime? BirthDate { get; set; }
    public string? MotherName { get; set; }
    public string? FatherName { get; set; }
    public string? Nationality { get; set; }
    public string? RacaCor { get; set; } // Raça/Cor (do CADSUS)
    
    // Endereço detalhado
    public string? ZipCode { get; set; } // CEP
    public string? Logradouro { get; set; } // Rua/Avenida
    public string? Numero { get; set; } // Número
    public string? Complemento { get; set; } // Apartamento, bloco, etc.
    public string? Bairro { get; set; } // Bairro
    public string? City { get; set; } // Município
    public string? State { get; set; } // Estado (UF)
    
    // Campo legado (manter por compatibilidade, depreciar depois)
    public string? Address { get; set; } // Endereço completo (formato antigo)
    
    // Foreign Keys - Vinculação municipal
    
    /// <summary>
    /// Município do paciente (baseado no código IBGE)
    /// </summary>
    public Guid? MunicipioId { get; set; }
    
    /// <summary>
    /// Unidade de saúde adscrita (onde o paciente está cadastrado)
    /// </summary>
    public Guid? UnidadeAdscritaId { get; set; }
    
    // Navigation Properties
    public User User { get; set; } = null!;
    public Municipality? Municipio { get; set; }
    public HealthFacility? UnidadeAdscrita { get; set; }
    
    // ===== RESPONSÁVEL LEGAL (para menores ou incapazes) =====
    
    /// <summary>
    /// Nome completo do responsável legal
    /// </summary>
    public string? ResponsavelNome { get; set; }
    
    /// <summary>
    /// CPF do responsável
    /// </summary>
    public string? ResponsavelCpf { get; set; }
    
    /// <summary>
    /// Telefone do responsável
    /// </summary>
    public string? ResponsavelTelefone { get; set; }
    
    /// <summary>
    /// Email do responsável
    /// </summary>
    public string? ResponsavelEmail { get; set; }
    
    /// <summary>
    /// Grau de parentesco: Mãe, Pai, Avó, Avô, Tio(a), Tutor, Curador, Outro
    /// </summary>
    public string? ResponsavelGrauParentesco { get; set; }
}
