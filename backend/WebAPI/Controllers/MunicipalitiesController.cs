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
public class MunicipalitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public MunicipalitiesController(ApplicationDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Lista todos os municípios cadastrados
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<MunicipalityDto>>> GetMunicipalities(
        [FromQuery] string? search = null,
        [FromQuery] bool? ativo = null)
    {
        try
        {
            var query = _context.Municipalities.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.ToLower();
                query = query.Where(m => m.Nome.ToLower().Contains(search) || 
                                        m.CodigoIBGE.Contains(search));
            }

            if (ativo.HasValue)
            {
                query = query.Where(m => m.Ativo == ativo.Value);
            }

            var municipalities = await query
                .OrderBy(m => m.Nome)
                .Select(m => new MunicipalityDto
                {
                    Id = m.Id,
                    CodigoIBGE = m.CodigoIBGE,
                    Nome = m.Nome,
                    UF = m.UF,
                    Ativo = m.Ativo,
                    DataAdesao = m.DataAdesao,
                    TotalEstabelecimentos = m.HealthFacilities.Count,
                    TotalPacientes = _context.PatientProfiles.Count(p => p.MunicipioId == m.Id)
                })
                .ToListAsync();

            return Ok(municipalities);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao buscar municípios", error = ex.Message });
        }
    }

    /// <summary>
    /// Obtém um município pelo ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<MunicipalityDto>> GetMunicipality(Guid id)
    {
        try
        {
            var municipality = await _context.Municipalities
                .Where(m => m.Id == id)
                .Select(m => new MunicipalityDto
                {
                    Id = m.Id,
                    CodigoIBGE = m.CodigoIBGE,
                    Nome = m.Nome,
                    UF = m.UF,
                    Ativo = m.Ativo,
                    DataAdesao = m.DataAdesao,
                    TotalEstabelecimentos = m.HealthFacilities.Count,
                    TotalPacientes = _context.PatientProfiles.Count(p => p.MunicipioId == m.Id)
                })
                .FirstOrDefaultAsync();

            if (municipality == null)
            {
                return NotFound(new { message = "Município não encontrado" });
            }

            return Ok(municipality);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao buscar município", error = ex.Message });
        }
    }

    /// <summary>
    /// Cria um novo município (apenas ADMIN ou REGULATOR)
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "ADMIN,REGULATOR")]
    public async Task<ActionResult<MunicipalityDto>> CreateMunicipality([FromBody] CreateMunicipalityDto dto)
    {
        try
        {
            // Validar código IBGE
            if (string.IsNullOrWhiteSpace(dto.CodigoIBGE) || dto.CodigoIBGE.Length != 7)
            {
                return BadRequest(new { message = "Código IBGE deve ter 7 dígitos" });
            }

            // Verificar se já existe
            var exists = await _context.Municipalities.AnyAsync(m => m.CodigoIBGE == dto.CodigoIBGE);
            if (exists)
            {
                return Conflict(new { message = "Município já cadastrado com este código IBGE" });
            }

            var municipality = new Municipality
            {
                CodigoIBGE = dto.CodigoIBGE,
                Nome = dto.Nome,
                UF = dto.UF.ToUpper(),
                Ativo = true,
                DataAdesao = DateTime.UtcNow
            };

            _context.Municipalities.Add(municipality);
            await _context.SaveChangesAsync();

            var result = new MunicipalityDto
            {
                Id = municipality.Id,
                CodigoIBGE = municipality.CodigoIBGE,
                Nome = municipality.Nome,
                UF = municipality.UF,
                Ativo = municipality.Ativo,
                DataAdesao = municipality.DataAdesao,
                TotalEstabelecimentos = 0,
                TotalPacientes = 0
            };

            return CreatedAtAction(nameof(GetMunicipality), new { id = municipality.Id }, result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao criar município", error = ex.Message });
        }
    }

    /// <summary>
    /// Atualiza um município (apenas ADMIN ou REGULATOR)
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "ADMIN,REGULATOR")]
    public async Task<ActionResult<MunicipalityDto>> UpdateMunicipality(Guid id, [FromBody] UpdateMunicipalityDto dto)
    {
        try
        {
            var municipality = await _context.Municipalities.FindAsync(id);
            if (municipality == null)
            {
                return NotFound(new { message = "Município não encontrado" });
            }

            if (!string.IsNullOrWhiteSpace(dto.Nome))
            {
                municipality.Nome = dto.Nome;
            }

            if (dto.Ativo.HasValue)
            {
                municipality.Ativo = dto.Ativo.Value;
            }

            municipality.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            var result = new MunicipalityDto
            {
                Id = municipality.Id,
                CodigoIBGE = municipality.CodigoIBGE,
                Nome = municipality.Nome,
                UF = municipality.UF,
                Ativo = municipality.Ativo,
                DataAdesao = municipality.DataAdesao,
                TotalEstabelecimentos = await _context.HealthFacilities.CountAsync(h => h.MunicipioId == id),
                TotalPacientes = await _context.PatientProfiles.CountAsync(p => p.MunicipioId == id)
            };

            return Ok(result);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao atualizar município", error = ex.Message });
        }
    }

    /// <summary>
    /// Remove um município (apenas ADMIN)
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult> DeleteMunicipality(Guid id)
    {
        try
        {
            var municipality = await _context.Municipalities.FindAsync(id);
            if (municipality == null)
            {
                return NotFound(new { message = "Município não encontrado" });
            }

            // Verificar se tem estabelecimentos vinculados
            var hasEstabelecimentos = await _context.HealthFacilities.AnyAsync(h => h.MunicipioId == id);
            if (hasEstabelecimentos)
            {
                return BadRequest(new { message = "Não é possível excluir município com estabelecimentos vinculados" });
            }

            _context.Municipalities.Remove(municipality);
            await _context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao excluir município", error = ex.Message });
        }
    }
}
