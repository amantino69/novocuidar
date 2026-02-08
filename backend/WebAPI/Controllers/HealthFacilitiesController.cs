using Application.DTOs.Municipal;
using Domain.Entities;
using Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HealthFacilitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public HealthFacilitiesController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lista estabelecimentos de saúde com filtros
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<HealthFacilityDto>>> GetHealthFacilities(
        [FromQuery] Guid? municipioId = null,
        [FromQuery] string? search = null,
        [FromQuery] string? tipoEstabelecimento = null,
        [FromQuery] bool? temConsultorioDigital = null,
        [FromQuery] bool? ativo = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        try
        {
            var query = _context.HealthFacilities
                .Include(h => h.Municipio)
                .AsQueryable();

            if (municipioId.HasValue)
            {
                query = query.Where(h => h.MunicipioId == municipioId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                // OTIMIZADO: Usar ILike nativo do PostgreSQL (case-insensitive sem ToLower)
                var searchPattern = $"%{search}%";
                query = query.Where(h => 
                    EF.Functions.ILike(h.NomeFantasia, searchPattern) || 
                    h.CodigoCNES.Contains(search) ||
                    (h.RazaoSocial != null && EF.Functions.ILike(h.RazaoSocial, searchPattern)));
            }

            if (!string.IsNullOrWhiteSpace(tipoEstabelecimento))
            {
                query = query.Where(h => h.TipoEstabelecimento == tipoEstabelecimento);
            }

            if (temConsultorioDigital.HasValue)
            {
                query = query.Where(h => h.TemConsultorioDigital == temConsultorioDigital.Value);
            }

            if (ativo.HasValue)
            {
                query = query.Where(h => h.Ativo == ativo.Value);
            }

            var total = await query.CountAsync();

            // OTIMIZAÇÃO: Buscar contagem de pacientes em uma única query
            var facilityIds = await query
                .OrderBy(h => h.NomeFantasia)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(h => h.Id)
                .ToListAsync();

            var patientCounts = await _context.PatientProfiles
                .Where(p => p.UnidadeAdscritaId != null && facilityIds.Contains(p.UnidadeAdscritaId.Value))
                .GroupBy(p => p.UnidadeAdscritaId)
                .Select(g => new { FacilityId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.FacilityId!.Value, x => x.Count);

            var facilities = await query
                .AsNoTracking()
                .OrderBy(h => h.NomeFantasia)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(h => new HealthFacilityDto
                {
                    Id = h.Id,
                    CodigoCNES = h.CodigoCNES,
                    NomeFantasia = h.NomeFantasia,
                    RazaoSocial = h.RazaoSocial,
                    TipoEstabelecimento = h.TipoEstabelecimento,
                    TipoEstabelecimentoDescricao = h.TipoEstabelecimentoDescricao,
                    CNPJ = h.CNPJ,
                    CEP = h.CEP,
                    Logradouro = h.Logradouro,
                    Numero = h.Numero,
                    Complemento = h.Complemento,
                    Bairro = h.Bairro,
                    Telefone = h.Telefone,
                    Email = h.Email,
                    Latitude = h.Latitude,
                    Longitude = h.Longitude,
                    TemConsultorioDigital = h.TemConsultorioDigital,
                    Ativo = h.Ativo,
                    UltimaSincronizacaoCNES = h.UltimaSincronizacaoCNES,
                    MunicipioId = h.MunicipioId,
                    MunicipioNome = h.Municipio.Nome,
                    MunicipioUF = h.Municipio.UF,
                    TotalPacientesAdscritos = 0 // Será preenchido abaixo
                })
                .ToListAsync();

            // Preencher contagem de pacientes
            foreach (var facility in facilities)
            {
                if (patientCounts.TryGetValue(facility.Id, out var count))
                    facility.TotalPacientesAdscritos = count;
            }

            return Ok(new
            {
                data = facilities,
                total,
                page,
                pageSize,
                totalPages = (int)Math.Ceiling(total / (double)pageSize)
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao buscar estabelecimentos", error = ex.Message });
        }
    }

    /// <summary>
    /// Obtém um estabelecimento pelo ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<HealthFacilityDto>> GetHealthFacility(Guid id)
    {
        try
        {
            var facility = await _context.HealthFacilities
                .Include(h => h.Municipio)
                .Where(h => h.Id == id)
                .Select(h => new HealthFacilityDto
                {
                    Id = h.Id,
                    CodigoCNES = h.CodigoCNES,
                    NomeFantasia = h.NomeFantasia,
                    RazaoSocial = h.RazaoSocial,
                    TipoEstabelecimento = h.TipoEstabelecimento,
                    TipoEstabelecimentoDescricao = h.TipoEstabelecimentoDescricao,
                    CNPJ = h.CNPJ,
                    CEP = h.CEP,
                    Logradouro = h.Logradouro,
                    Numero = h.Numero,
                    Complemento = h.Complemento,
                    Bairro = h.Bairro,
                    Telefone = h.Telefone,
                    Email = h.Email,
                    Latitude = h.Latitude,
                    Longitude = h.Longitude,
                    TemConsultorioDigital = h.TemConsultorioDigital,
                    Ativo = h.Ativo,
                    UltimaSincronizacaoCNES = h.UltimaSincronizacaoCNES,
                    MunicipioId = h.MunicipioId,
                    MunicipioNome = h.Municipio.Nome,
                    MunicipioUF = h.Municipio.UF,
                    TotalPacientesAdscritos = _context.PatientProfiles.Count(p => p.UnidadeAdscritaId == h.Id)
                })
                .FirstOrDefaultAsync();

            if (facility == null)
            {
                return NotFound(new { message = "Estabelecimento não encontrado" });
            }

            return Ok(facility);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao buscar estabelecimento", error = ex.Message });
        }
    }

    /// <summary>
    /// Cria um novo estabelecimento de saúde (ADMIN ou REGULATOR)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "ADMIN,REGULATOR")]
    public async Task<ActionResult<HealthFacilityDto>> CreateHealthFacility([FromBody] CreateHealthFacilityDto dto)
    {
        try
        {
            // Validar município
            var municipio = await _context.Municipalities.FindAsync(dto.MunicipioId);
            if (municipio == null)
            {
                return BadRequest(new { message = "Município não encontrado" });
            }

            // Verificar se CNES já existe
            var exists = await _context.HealthFacilities.AnyAsync(h => h.CodigoCNES == dto.CodigoCNES);
            if (exists)
            {
                return Conflict(new { message = "Estabelecimento já cadastrado com este código CNES" });
            }

            var facility = new HealthFacility
            {
                CodigoCNES = dto.CodigoCNES,
                NomeFantasia = dto.NomeFantasia,
                RazaoSocial = dto.RazaoSocial,
                TipoEstabelecimento = dto.TipoEstabelecimento,
                TipoEstabelecimentoDescricao = dto.TipoEstabelecimentoDescricao,
                CNPJ = dto.CNPJ,
                CEP = dto.CEP,
                Logradouro = dto.Logradouro,
                Numero = dto.Numero,
                Complemento = dto.Complemento,
                Bairro = dto.Bairro,
                Telefone = dto.Telefone,
                Email = dto.Email,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                MunicipioId = dto.MunicipioId,
                TemConsultorioDigital = false,
                Ativo = true
            };

            _context.HealthFacilities.Add(facility);
            await _context.SaveChangesAsync();

            var result = new HealthFacilityDto
            {
                Id = facility.Id,
                CodigoCNES = facility.CodigoCNES,
                NomeFantasia = facility.NomeFantasia,
                RazaoSocial = facility.RazaoSocial,
                TipoEstabelecimento = facility.TipoEstabelecimento,
                TipoEstabelecimentoDescricao = facility.TipoEstabelecimentoDescricao,
                CNPJ = facility.CNPJ,
                CEP = facility.CEP,
                Logradouro = facility.Logradouro,
                Numero = facility.Numero,
                Complemento = facility.Complemento,
                Bairro = facility.Bairro,
                Telefone = facility.Telefone,
                Email = facility.Email,
                Latitude = facility.Latitude,
                Longitude = facility.Longitude,
                TemConsultorioDigital = facility.TemConsultorioDigital,
                Ativo = facility.Ativo,
                MunicipioId = facility.MunicipioId,
                MunicipioNome = municipio.Nome,
                MunicipioUF = municipio.UF,
                TotalPacientesAdscritos = 0
            };

            return CreatedAtAction(nameof(GetHealthFacility), new { id = facility.Id }, result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao criar estabelecimento", error = ex.Message });
        }
    }

    /// <summary>
    /// Atualiza um estabelecimento de saúde (ADMIN ou REGULATOR)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "ADMIN,REGULATOR")]
    public async Task<ActionResult<HealthFacilityDto>> UpdateHealthFacility(Guid id, [FromBody] UpdateHealthFacilityDto dto)
    {
        try
        {
            var facility = await _context.HealthFacilities
                .Include(h => h.Municipio)
                .FirstOrDefaultAsync(h => h.Id == id);

            if (facility == null)
            {
                return NotFound(new { message = "Estabelecimento não encontrado" });
            }

            if (!string.IsNullOrWhiteSpace(dto.NomeFantasia))
            {
                facility.NomeFantasia = dto.NomeFantasia;
            }

            if (!string.IsNullOrWhiteSpace(dto.Telefone))
            {
                facility.Telefone = dto.Telefone;
            }

            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                facility.Email = dto.Email;
            }

            if (dto.TemConsultorioDigital.HasValue)
            {
                facility.TemConsultorioDigital = dto.TemConsultorioDigital.Value;
            }

            if (dto.Ativo.HasValue)
            {
                facility.Ativo = dto.Ativo.Value;
            }

            facility.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var result = new HealthFacilityDto
            {
                Id = facility.Id,
                CodigoCNES = facility.CodigoCNES,
                NomeFantasia = facility.NomeFantasia,
                RazaoSocial = facility.RazaoSocial,
                TipoEstabelecimento = facility.TipoEstabelecimento,
                TipoEstabelecimentoDescricao = facility.TipoEstabelecimentoDescricao,
                CNPJ = facility.CNPJ,
                CEP = facility.CEP,
                Logradouro = facility.Logradouro,
                Numero = facility.Numero,
                Complemento = facility.Complemento,
                Bairro = facility.Bairro,
                Telefone = facility.Telefone,
                Email = facility.Email,
                Latitude = facility.Latitude,
                Longitude = facility.Longitude,
                TemConsultorioDigital = facility.TemConsultorioDigital,
                Ativo = facility.Ativo,
                UltimaSincronizacaoCNES = facility.UltimaSincronizacaoCNES,
                MunicipioId = facility.MunicipioId,
                MunicipioNome = facility.Municipio.Nome,
                MunicipioUF = facility.Municipio.UF,
                TotalPacientesAdscritos = await _context.PatientProfiles.CountAsync(p => p.UnidadeAdscritaId == id)
            };

            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao atualizar estabelecimento", error = ex.Message });
        }
    }

    /// <summary>
    /// Remove um estabelecimento (apenas ADMIN)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult> DeleteHealthFacility(Guid id)
    {
        try
        {
            var facility = await _context.HealthFacilities.FindAsync(id);
            if (facility == null)
            {
                return NotFound(new { message = "Estabelecimento não encontrado" });
            }

            // Verificar se tem pacientes vinculados
            var hasPacientes = await _context.PatientProfiles.AnyAsync(p => p.UnidadeAdscritaId == id);
            if (hasPacientes)
            {
                return BadRequest(new { message = "Não é possível excluir estabelecimento com pacientes vinculados" });
            }

            _context.HealthFacilities.Remove(facility);
            await _context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao excluir estabelecimento", error = ex.Message });
        }
    }

    /// <summary>
    /// Lista estabelecimentos por município (simplificado para dropdown)
    /// </summary>
    [HttpGet("by-municipality/{municipioId}")]
    public async Task<ActionResult> GetByMunicipality(Guid municipioId)
    {
        try
        {
            var facilities = await _context.HealthFacilities
                .Where(h => h.MunicipioId == municipioId && h.Ativo)
                .OrderBy(h => h.NomeFantasia)
                .Select(h => new
                {
                    h.Id,
                    h.CodigoCNES,
                    h.NomeFantasia,
                    h.TipoEstabelecimento,
                    h.TemConsultorioDigital
                })
                .ToListAsync();

            return Ok(facilities);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao buscar estabelecimentos", error = ex.Message });
        }
    }
}
