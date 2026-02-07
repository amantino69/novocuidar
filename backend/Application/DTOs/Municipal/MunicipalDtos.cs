namespace Application.DTOs.Municipal;

/// <summary>
/// DTO para listagem de municípios
/// </summary>
public class MunicipalityDto
{
    public Guid Id { get; set; }
    public string CodigoIBGE { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string UF { get; set; } = string.Empty;
    public bool Ativo { get; set; }
    public DateTime? DataAdesao { get; set; }
    public int TotalEstabelecimentos { get; set; }
    public int TotalPacientes { get; set; }
}

/// <summary>
/// DTO para criação de município
/// </summary>
public class CreateMunicipalityDto
{
    public string CodigoIBGE { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public string UF { get; set; } = string.Empty;
}

/// <summary>
/// DTO para atualização de município
/// </summary>
public class UpdateMunicipalityDto
{
    public string? Nome { get; set; }
    public bool? Ativo { get; set; }
}

/// <summary>
/// DTO para listagem de estabelecimentos de saúde
/// </summary>
public class HealthFacilityDto
{
    public Guid Id { get; set; }
    public string CodigoCNES { get; set; } = string.Empty;
    public string NomeFantasia { get; set; } = string.Empty;
    public string? RazaoSocial { get; set; }
    public string? TipoEstabelecimento { get; set; }
    public string? TipoEstabelecimentoDescricao { get; set; }
    public string? CNPJ { get; set; }
    public string? EnderecoCompleto { get; set; }
    public string? CEP { get; set; }
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? Telefone { get; set; }
    public string? Email { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool TemConsultorioDigital { get; set; }
    public bool Ativo { get; set; }
    public DateTime? UltimaSincronizacaoCNES { get; set; }
    
    // Dados do município
    public Guid MunicipioId { get; set; }
    public string? MunicipioNome { get; set; }
    public string? MunicipioUF { get; set; }
    
    // Estatísticas
    public int TotalPacientesAdscritos { get; set; }
}

/// <summary>
/// DTO para criação de estabelecimento de saúde
/// </summary>
public class CreateHealthFacilityDto
{
    public string CodigoCNES { get; set; } = string.Empty;
    public string NomeFantasia { get; set; } = string.Empty;
    public string? RazaoSocial { get; set; }
    public string? TipoEstabelecimento { get; set; }
    public string? TipoEstabelecimentoDescricao { get; set; }
    public string? CNPJ { get; set; }
    public string? CEP { get; set; }
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? Telefone { get; set; }
    public string? Email { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public Guid MunicipioId { get; set; }
}

/// <summary>
/// DTO para atualização de estabelecimento de saúde
/// </summary>
public class UpdateHealthFacilityDto
{
    public string? NomeFantasia { get; set; }
    public string? Telefone { get; set; }
    public string? Email { get; set; }
    public bool? TemConsultorioDigital { get; set; }
    public bool? Ativo { get; set; }
}

/// <summary>
/// DTO para importação de estabelecimentos do CNES
/// </summary>
public class ImportCnesDto
{
    public string CodigoIBGE { get; set; } = string.Empty;
}

/// <summary>
/// DTO de resposta da importação CNES
/// </summary>
public class ImportCnesResultDto
{
    public int TotalImportados { get; set; }
    public int TotalAtualizados { get; set; }
    public int TotalErros { get; set; }
    public List<string> Erros { get; set; } = new();
}

/// <summary>
/// DTO para dados do CNES retornados pela API do DATASUS
/// </summary>
public class CnesEstabelecimentoDto
{
    public string CodigoCnes { get; set; } = string.Empty;
    public string NomeFantasia { get; set; } = string.Empty;
    public string? RazaoSocial { get; set; }
    public string? TipoUnidade { get; set; }
    public string? TipoUnidadeDescricao { get; set; }
    public string? Cnpj { get; set; }
    public string? Cep { get; set; }
    public string? Logradouro { get; set; }
    public string? Numero { get; set; }
    public string? Complemento { get; set; }
    public string? Bairro { get; set; }
    public string? Telefone { get; set; }
    public string? Email { get; set; }
    public string? CodigoMunicipio { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
}

/// <summary>
/// DTO para filtros de busca de estabelecimentos
/// </summary>
public class HealthFacilityFilterDto
{
    public string? CodigoIBGE { get; set; }
    public string? Search { get; set; }
    public string? TipoEstabelecimento { get; set; }
    public bool? TemConsultorioDigital { get; set; }
    public bool? Ativo { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
