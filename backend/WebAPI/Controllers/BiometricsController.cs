using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using Infrastructure.Data;
using WebAPI.Hubs;
using System.Text.Json;

namespace WebAPI.Controllers;

/// <summary>
/// Controller para gerenciar dados biométricos em tempo real durante teleconsultas
/// </summary>
[ApiController]
[Route("api/appointments/{appointmentId}/[controller]")]
public class BiometricsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<TeleconsultationHub> _hubContext;

    public BiometricsController(ApplicationDbContext context, IHubContext<TeleconsultationHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }

    /// <summary>
    /// Obtém os dados biométricos atuais de uma consulta
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<BiometricsDto>> GetBiometrics(Guid appointmentId)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        if (string.IsNullOrEmpty(appointment.BiometricsJson))
            return Ok(new BiometricsDto());

        var biometrics = JsonSerializer.Deserialize<BiometricsDto>(appointment.BiometricsJson);
        return Ok(biometrics);
    }

    /// <summary>
    /// Atualiza os dados biométricos de uma consulta (usado pelo paciente)
    /// </summary>
    [HttpPut]
    public async Task<ActionResult> UpdateBiometrics(Guid appointmentId, [FromBody] BiometricsDto dto)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        dto.LastUpdated = DateTime.UtcNow.ToString("o");
        appointment.BiometricsJson = JsonSerializer.Serialize(dto);
        
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Biométricos atualizados com sucesso", data = dto });
    }

    /// <summary>
    /// Verifica se houve atualização desde uma determinada data (para polling eficiente)
    /// </summary>
    [HttpHead]
    public async Task<ActionResult> CheckUpdate(Guid appointmentId, [FromQuery] string? since)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        
        if (appointment == null)
            return NotFound();

        if (string.IsNullOrEmpty(appointment.BiometricsJson))
            return NoContent(); // 204 - no data yet

        var biometrics = JsonSerializer.Deserialize<BiometricsDto>(appointment.BiometricsJson);
        
        if (string.IsNullOrEmpty(since) || string.IsNullOrEmpty(biometrics?.LastUpdated))
            return Ok(); // Has data

        // Compare timestamps
        if (DateTime.TryParse(since, out var sinceDate) && 
            DateTime.TryParse(biometrics.LastUpdated, out var lastUpdated))
        {
            if (lastUpdated > sinceDate)
                return Ok(); // Has updates
            else
                return NoContent(); // No updates since
        }

        return Ok();
    }
}

/// <summary>
/// Controller para receber leituras BLE de dispositivos externos (Python bridge)
/// Também fornece endpoint para maleta itinerante detectar consulta ativa
/// </summary>
[ApiController]
[Route("api/biometrics")]
public class BleBridgeController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<TeleconsultationHub> _hubContext;
    private readonly ILogger<BleBridgeController> _logger;

    public BleBridgeController(
        ApplicationDbContext context, 
        IHubContext<TeleconsultationHub> hubContext,
        ILogger<BleBridgeController> logger)
    {
        _context = context;
        _hubContext = hubContext;
        _logger = logger;
    }

    /// <summary>
    /// Retorna a consulta ativa no momento (para maleta itinerante)
    /// Status 2 = Em Andamento, iniciada nas últimas 2 horas
    /// </summary>
    [HttpGet("active-appointment")]
    public async Task<ActionResult> GetActiveAppointment()
    {
        var today = DateTime.Today;
        
        var activeAppointment = await _context.Appointments
            .Where(a => a.Status == Domain.Enums.AppointmentStatus.InProgress)
            .Where(a => a.Date >= today)
            .OrderByDescending(a => a.UpdatedAt)
            .Select(a => new { a.Id, a.PatientId, a.ProfessionalId, a.Date, a.Time })
            .FirstOrDefaultAsync();
        
        if (activeAppointment == null)
            return NotFound(new { message = "Nenhuma consulta ativa no momento" });
        
        _logger.LogInformation("[Maleta Itinerante] Consulta ativa: {Id}", activeAppointment.Id);
        return Ok(activeAppointment);
    }

    /// <summary>
    /// Recebe leitura de dispositivo BLE e envia via SignalR para o médico
    /// </summary>
    [HttpPost("ble-reading")]
    public async Task<ActionResult> ReceiveBleReading([FromBody] BleReadingDto dto)
    {
        _logger.LogInformation("[BLE Bridge] Leitura recebida: {Type} = {@Values}", dto.DeviceType, dto.Values);

        // Busca a consulta
        if (!Guid.TryParse(dto.AppointmentId, out var appointmentId))
            return BadRequest(new { message = "appointmentId inválido" });

        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        // Atualiza biometrics
        var biometrics = string.IsNullOrEmpty(appointment.BiometricsJson)
            ? new BiometricsDto()
            : JsonSerializer.Deserialize<BiometricsDto>(appointment.BiometricsJson) ?? new BiometricsDto();

        // Aplica valores baseado no tipo
        switch (dto.DeviceType?.ToLower())
        {
            case "scale":
                if (dto.Values.TryGetValue("weight", out var weight))
                    biometrics.Weight = ConvertToDecimal(weight);
                break;
            case "blood_pressure":
                if (dto.Values.TryGetValue("systolic", out var sys))
                    biometrics.BloodPressureSystolic = ConvertToInt(sys);
                if (dto.Values.TryGetValue("diastolic", out var dia))
                    biometrics.BloodPressureDiastolic = ConvertToInt(dia);
                if (dto.Values.TryGetValue("heartRate", out var hr))
                    biometrics.HeartRate = ConvertToInt(hr);
                break;
            case "oximeter":
                if (dto.Values.TryGetValue("spo2", out var spo2))
                    biometrics.OxygenSaturation = ConvertToInt(spo2);
                if (dto.Values.TryGetValue("pulseRate", out var pulse))
                    biometrics.HeartRate = ConvertToInt(pulse);
                break;
            case "thermometer":
                if (dto.Values.TryGetValue("temperature", out var temp))
                    biometrics.Temperature = ConvertToDecimal(temp);
                break;
        }

        biometrics.LastUpdated = DateTime.UtcNow.ToString("o");
        appointment.BiometricsJson = JsonSerializer.Serialize(biometrics);
        await _context.SaveChangesAsync();

        // Envia via SignalR para todos na sala da consulta
        await _hubContext.Clients.Group($"appointment_{appointmentId}")
            .SendAsync("BiometricsUpdated", new
            {
                appointmentId = dto.AppointmentId,
                deviceType = dto.DeviceType,
                values = dto.Values,
                biometrics,
                timestamp = biometrics.LastUpdated
            });

        _logger.LogInformation("[BLE Bridge] Dados enviados via SignalR para appointment_{Id}", appointmentId);

        return Ok(new { message = "Leitura processada", biometrics });
    }
    
    /// <summary>
    /// Converte JsonElement ou objeto para decimal
    /// </summary>
    private static decimal ConvertToDecimal(object value)
    {
        if (value is JsonElement je)
        {
            return je.ValueKind switch
            {
                JsonValueKind.Number => je.GetDecimal(),
                JsonValueKind.String => decimal.Parse(je.GetString() ?? "0"),
                _ => 0
            };
        }
        return Convert.ToDecimal(value);
    }
    
    /// <summary>
    /// Converte JsonElement ou objeto para int
    /// </summary>
    private static int ConvertToInt(object value)
    {
        if (value is JsonElement je)
        {
            return je.ValueKind switch
            {
                JsonValueKind.Number => je.GetInt32(),
                JsonValueKind.String => int.Parse(je.GetString() ?? "0"),
                _ => 0
            };
        }
        return Convert.ToInt32(value);
    }
}

public class BleReadingDto
{
    public string? AppointmentId { get; set; }
    public string? DeviceType { get; set; }
    public string? Timestamp { get; set; }
    public Dictionary<string, object> Values { get; set; } = new();
}

public class BiometricsDto
{
    public int? HeartRate { get; set; }
    public int? BloodPressureSystolic { get; set; }
    public int? BloodPressureDiastolic { get; set; }
    public int? OxygenSaturation { get; set; }
    public decimal? Temperature { get; set; }
    public int? RespiratoryRate { get; set; }
    public int? Glucose { get; set; }
    public decimal? Weight { get; set; }
    public decimal? Height { get; set; }
    public string? LastUpdated { get; set; }
}
