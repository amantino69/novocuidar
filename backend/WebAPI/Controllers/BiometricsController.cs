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
    private readonly IHubContext<MedicalDevicesHub> _medicalDevicesHubContext;
    private readonly ILogger<BleBridgeController> _logger;

    public BleBridgeController(
        ApplicationDbContext context, 
        IHubContext<MedicalDevicesHub> medicalDevicesHubContext,
        ILogger<BleBridgeController> logger)
    {
        _context = context;
        _medicalDevicesHubContext = medicalDevicesHubContext;
        _logger = logger;
    }

    // Cache estático para consulta marcada como "Acontecendo" pelo paciente
    private static string? _acontecendoAppointmentId = null;
    private static DateTime? _acontecendoTimestamp = null;
    private static readonly TimeSpan AcontecendoTimeout = TimeSpan.FromHours(4); // Expira após 4 horas

    /// <summary>
    /// Marca uma consulta como "Acontecendo" (chamado pelo paciente/operador)
    /// </summary>
    [HttpPost("acontecendo/{appointmentId}")]
    public async Task<ActionResult> MarcarAcontecendo(Guid appointmentId)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        _acontecendoAppointmentId = appointmentId.ToString();
        _acontecendoTimestamp = DateTime.UtcNow;
        
        _logger.LogInformation("[Acontecendo] Consulta marcada: {Id}", appointmentId);
        return Ok(new { message = "Consulta marcada como acontecendo", appointmentId });
    }

    /// <summary>
    /// Remove a marcação "Acontecendo" (chamado ao finalizar consulta)
    /// </summary>
    [HttpDelete("acontecendo")]
    public ActionResult DesmarcarAcontecendo()
    {
        var oldId = _acontecendoAppointmentId;
        _acontecendoAppointmentId = null;
        _acontecendoTimestamp = null;
        
        _logger.LogInformation("[Acontecendo] Desmarcado. Anterior: {Id}", oldId);
        return Ok(new { message = "Status acontecendo removido" });
    }

    /// <summary>
    /// Verifica se há consulta marcada como "Acontecendo"
    /// </summary>
    [HttpGet("acontecendo")]
    public ActionResult GetAcontecendo()
    {
        // Verifica se expirou
        if (_acontecendoTimestamp != null && 
            DateTime.UtcNow - _acontecendoTimestamp.Value > AcontecendoTimeout)
        {
            _acontecendoAppointmentId = null;
            _acontecendoTimestamp = null;
        }

        if (string.IsNullOrEmpty(_acontecendoAppointmentId))
            return Ok(new { appointmentId = (string?)null, message = "Nenhuma consulta acontecendo" });

        return Ok(new { 
            appointmentId = _acontecendoAppointmentId, 
            since = _acontecendoTimestamp 
        });
    }

    /// <summary>
    /// Retorna a consulta ativa no momento (para maleta itinerante)
    /// PRIORIDADE: 1) Marcada como "Acontecendo" 2) InProgress 3) Scheduled/Confirmed
    /// </summary>
    [HttpGet("active-appointment")]
    public async Task<ActionResult> GetActiveAppointment()
    {
        // PRIORIDADE 1: Consulta marcada como "Acontecendo" pelo paciente
        if (!string.IsNullOrEmpty(_acontecendoAppointmentId) && 
            _acontecendoTimestamp != null &&
            DateTime.UtcNow - _acontecendoTimestamp.Value <= AcontecendoTimeout)
        {
            if (Guid.TryParse(_acontecendoAppointmentId, out var acontecendoGuid))
            {
                var acontecendo = await _context.Appointments
                    .Where(a => a.Id == acontecendoGuid)
                    .Select(a => new { a.Id, a.PatientId, a.ProfessionalId, a.Date, a.Time })
                    .FirstOrDefaultAsync();
                
                if (acontecendo != null)
                {
                    _logger.LogInformation("[Maleta] Consulta ACONTECENDO: {Id}", acontecendo.Id);
                    return Ok(acontecendo);
                }
            }
        }

        // PRIORIDADE 2: Consultas InProgress (mais recente primeiro)
        var activeAppointment = await _context.Appointments
            .Where(a => a.Status == Domain.Enums.AppointmentStatus.InProgress)
            .OrderByDescending(a => a.UpdatedAt)
            .Select(a => new { a.Id, a.PatientId, a.ProfessionalId, a.Date, a.Time })
            .FirstOrDefaultAsync();
        
        // PRIORIDADE 3: Scheduled/Confirmed mais recente
        if (activeAppointment == null)
        {
            activeAppointment = await _context.Appointments
                .Where(a => a.Status == Domain.Enums.AppointmentStatus.Scheduled || 
                           a.Status == Domain.Enums.AppointmentStatus.Confirmed)
                .OrderByDescending(a => a.UpdatedAt)
                .Select(a => new { a.Id, a.PatientId, a.ProfessionalId, a.Date, a.Time })
                .FirstOrDefaultAsync();
        }
        
        if (activeAppointment == null)
        {
            _logger.LogWarning("[Maleta] Nenhuma consulta encontrada");
            return NotFound(new { message = "Nenhuma consulta ativa no momento" });
        }
        
        _logger.LogInformation("[Maleta] Consulta ativa: {Id}", activeAppointment.Id);
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

        // Envia via SignalR para todos na sala da consulta (MedicalDevicesHub)
        await _medicalDevicesHubContext.Clients.Group($"appointment_{appointmentId}")
            .SendAsync("BiometricsUpdated", new
            {
                appointmentId = dto.AppointmentId,
                deviceType = dto.DeviceType,
                values = dto.Values,
                biometrics,
                timestamp = biometrics.LastUpdated
            });

        _logger.LogInformation("[BLE Bridge] Dados enviados via MedicalDevicesHub para appointment_{Id}", appointmentId);

        // Também atualiza o cache global (para botão "Capturar Sinais")
        if (!string.IsNullOrEmpty(dto.DeviceType))
        {
            BleCacheStore.UpdateCache(dto.DeviceType.ToLower(), dto.Values);
            _logger.LogInformation("[BLE Cache] Cache atualizado para {Type}", dto.DeviceType);
        }

        return Ok(new { message = "Leitura processada", biometrics });
    }
    
    /// <summary>
    /// Armazena leitura BLE no cache (para recuperação posterior pelo botão "Capturar Sinais")
    /// Usado quando não há consulta ativa específica, mas o dispositivo capturou dados
    /// </summary>
    [HttpPost("ble-cache")]
    public ActionResult StoreBleCache([FromBody] BleReadingDto dto)
    {
        if (string.IsNullOrEmpty(dto.DeviceType))
            return BadRequest(new { message = "deviceType é obrigatório" });
        
        BleCacheStore.UpdateCache(dto.DeviceType.ToLower(), dto.Values);
        _logger.LogInformation("[BLE Cache] Armazenado: {Type} = {@Values}", dto.DeviceType, dto.Values);
        
        return Ok(new { message = "Leitura armazenada no cache", deviceType = dto.DeviceType, values = dto.Values });
    }
    
    /// <summary>
    /// Recebe fonocardiograma do estetoscópio Eko CORE 500
    /// O áudio é salvo em disco e enviado via SignalR para o médico
    /// </summary>
    [HttpPost("phonocardiogram")]
    public async Task<ActionResult> ReceivePhonocardiogram([FromBody] PhonocardiogramDto dto)
    {
        _logger.LogInformation("[Fonocardiograma] Recebido: {Duration}s, HeartRate={HeartRate}", 
            dto.DurationSeconds, dto.Values?.GetValueOrDefault("heartRate"));

        // Valida appointmentId
        if (!Guid.TryParse(dto.AppointmentId, out var appointmentId))
            return BadRequest(new { message = "appointmentId inválido" });

        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null)
            return NotFound(new { message = "Consulta não encontrada" });

        // Atualiza frequência cardíaca nos biometrics se detectada
        if (dto.Values != null && dto.Values.TryGetValue("heartRate", out var hrObj) && hrObj != null)
        {
            var biometrics = string.IsNullOrEmpty(appointment.BiometricsJson)
                ? new BiometricsDto()
                : JsonSerializer.Deserialize<BiometricsDto>(appointment.BiometricsJson) ?? new BiometricsDto();

            biometrics.HeartRate = ConvertToInt(hrObj);
            biometrics.LastUpdated = DateTime.UtcNow.ToString("o");
            appointment.BiometricsJson = JsonSerializer.Serialize(biometrics);
            await _context.SaveChangesAsync();
        }

        // Salva áudio em arquivo WAV
        string? audioFilePath = null;
        if (!string.IsNullOrEmpty(dto.AudioData))
        {
            try
            {
                var pcmBytes = Convert.FromBase64String(dto.AudioData);
                var uploadDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "phonocardiograms");
                Directory.CreateDirectory(uploadDir);
                
                var fileName = $"phono_{appointmentId}_{DateTime.UtcNow:yyyyMMddHHmmss}.wav";
                var filePath = Path.Combine(uploadDir, fileName);
                
                // Cria arquivo WAV
                using (var fs = new FileStream(filePath, FileMode.Create))
                using (var writer = new BinaryWriter(fs))
                {
                    var sampleRate = dto.SampleRate ?? 8000;
                    var numSamples = pcmBytes.Length / 2; // 16-bit samples
                    
                    // WAV Header
                    writer.Write(new char[] { 'R', 'I', 'F', 'F' });
                    writer.Write(36 + pcmBytes.Length); // File size - 8
                    writer.Write(new char[] { 'W', 'A', 'V', 'E' });
                    
                    // fmt chunk
                    writer.Write(new char[] { 'f', 'm', 't', ' ' });
                    writer.Write(16); // Chunk size
                    writer.Write((short)1); // PCM format
                    writer.Write((short)1); // Mono
                    writer.Write(sampleRate);
                    writer.Write(sampleRate * 2); // Byte rate
                    writer.Write((short)2); // Block align
                    writer.Write((short)16); // Bits per sample
                    
                    // data chunk
                    writer.Write(new char[] { 'd', 'a', 't', 'a' });
                    writer.Write(pcmBytes.Length);
                    writer.Write(pcmBytes);
                }
                
                audioFilePath = $"/phonocardiograms/{fileName}";
                _logger.LogInformation("[Fonocardiograma] Áudio salvo: {Path}", audioFilePath);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[Fonocardiograma] Erro ao salvar áudio");
            }
        }

        // Envia via SignalR para médico (inclui URL do áudio)
        await _medicalDevicesHubContext.Clients.Group($"appointment_{appointmentId}")
            .SendAsync("PhonocardiogramReceived", new
            {
                appointmentId = dto.AppointmentId,
                deviceType = "stethoscope",
                heartRate = dto.Values?.GetValueOrDefault("heartRate"),
                audioUrl = audioFilePath,
                sampleRate = dto.SampleRate ?? 8000,
                durationSeconds = dto.DurationSeconds,
                timestamp = DateTime.UtcNow.ToString("o")
            });

        _logger.LogInformation("[Fonocardiograma] Enviado via SignalR para appointment_{Id}", appointmentId);

        return Ok(new { 
            message = "Fonocardiograma recebido", 
            audioUrl = audioFilePath,
            heartRate = dto.Values?.GetValueOrDefault("heartRate")
        });
    }
    
    /// <summary>
    /// Retorna todas as leituras BLE em cache (usado pelo botão "Capturar Sinais")
    /// O frontend pode buscar os dados e aplicar na consulta específica
    /// </summary>
    [HttpGet("ble-cache")]
    public ActionResult GetBleCache()
    {
        // Limpa entradas com mais de 5 minutos
        BleCacheStore.ClearOldEntries(TimeSpan.FromMinutes(5));
        
        var cache = BleCacheStore.GetAllCache();
        
        if (cache.Count == 0)
            return Ok(new { message = "Nenhuma leitura recente", devices = new Dictionary<string, object>() });
        
        var result = new Dictionary<string, object>();
        foreach (var kvp in cache)
        {
            result[kvp.Key] = new
            {
                values = kvp.Value.Values,
                timestamp = kvp.Value.Timestamp.ToString("o"),
                ageSeconds = (DateTime.UtcNow - kvp.Value.Timestamp).TotalSeconds
            };
        }
        
        _logger.LogInformation("[BLE Cache] Consulta de cache: {Count} dispositivos", cache.Count);
        return Ok(new { message = "Cache recuperado", devices = result });
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

/// <summary>
/// Cache estático para últimas leituras BLE (solução para múltiplas consultas em andamento)
/// </summary>
public static class BleCacheStore
{
    private static readonly Dictionary<string, BleCacheEntry> _cache = new();
    private static readonly object _lock = new object();
    
    public static void UpdateCache(string deviceType, Dictionary<string, object> values)
    {
        lock (_lock)
        {
            _cache[deviceType] = new BleCacheEntry
            {
                DeviceType = deviceType,
                Values = values,
                Timestamp = DateTime.UtcNow
            };
        }
    }
    
    public static Dictionary<string, BleCacheEntry> GetAllCache()
    {
        lock (_lock)
        {
            return new Dictionary<string, BleCacheEntry>(_cache);
        }
    }
    
    public static void ClearOldEntries(TimeSpan maxAge)
    {
        lock (_lock)
        {
            var cutoff = DateTime.UtcNow - maxAge;
            var keysToRemove = _cache.Where(kvp => kvp.Value.Timestamp < cutoff).Select(kvp => kvp.Key).ToList();
            foreach (var key in keysToRemove)
            {
                _cache.Remove(key);
            }
        }
    }
}

public class BleCacheEntry
{
    public string DeviceType { get; set; } = "";
    public Dictionary<string, object> Values { get; set; } = new();
    public DateTime Timestamp { get; set; }
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

public class PhonocardiogramDto
{
    public string? AppointmentId { get; set; }
    public string? DeviceType { get; set; }
    public string? Timestamp { get; set; }
    public Dictionary<string, object>? Values { get; set; }
    public string? AudioData { get; set; }  // Base64 encoded PCM audio
    public int? SampleRate { get; set; }
    public string? Format { get; set; }  // "pcm_s16le"
    public double? DurationSeconds { get; set; }
}
