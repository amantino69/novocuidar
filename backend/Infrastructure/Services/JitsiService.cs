using Application.DTOs.Jitsi;
using Application.Interfaces;
using Domain.Enums;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Text;

namespace Infrastructure.Services;

/// <summary>
/// Serviço para gerenciamento de tokens JWT do Jitsi Meet
/// Implementa autenticação segura para videochamadas self-hosted
/// </summary>
public class JitsiService : IJitsiService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    
    // Configurações do Jitsi carregadas de variáveis de ambiente
    private readonly bool _enabled;
    private readonly string _domain;
    private readonly string _appId;
    private readonly string _appSecret;
    private readonly int _tokenExpirationMinutes;
    private readonly bool _requiresAuth;
    private readonly bool _dynamicDomain;
    private readonly int _jitsiPort;

    public JitsiService(ApplicationDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
        
        // Carregar configurações do Jitsi (prioridade: variáveis de ambiente > appsettings)
        _enabled = GetConfigValue("JITSI_ENABLED", "JitsiSettings:Enabled", "true").ToLower() == "true";
        _domain = GetConfigValue("JITSI_DOMAIN", "JitsiSettings:Domain", "meet.jit.si");
        _appId = GetConfigValue("JITSI_APP_ID", "JitsiSettings:AppId", "telecuidar");
        _appSecret = GetConfigValue("JITSI_APP_SECRET", "JitsiSettings:AppSecret", "");
        _tokenExpirationMinutes = int.TryParse(
            GetConfigValue("JITSI_TOKEN_EXPIRATION_MINUTES", "JitsiSettings:TokenExpirationMinutes", "120"),
            out var expMin) ? expMin : 120;
        _requiresAuth = GetConfigValue("JITSI_REQUIRES_AUTH", "JitsiSettings:RequiresAuth", "true").ToLower() == "true";
        _dynamicDomain = GetConfigValue("JITSI_DYNAMIC_DOMAIN", "JitsiSettings:DynamicDomain", "false").ToLower() == "true";
        
        // Extrair porta do domínio configurado (ex: localhost:8443 -> 8443)
        var domainParts = _domain.Split(':');
        _jitsiPort = domainParts.Length > 1 && int.TryParse(domainParts[1], out var port) ? port : 8443;
    }

    private string GetConfigValue(string envKey, string configKey, string defaultValue)
    {
        return Environment.GetEnvironmentVariable(envKey)
            ?? _configuration[configKey]
            ?? defaultValue;
    }

    /// <summary>
    /// Resolve o domínio do Jitsi baseado no host da requisição (para dev) ou configuração fixa (para prod)
    /// </summary>
    private string ResolveDomain(string? requestHost)
    {
        // Se domínio dinâmico está desabilitado ou não tem host, usa configuração fixa
        if (!_dynamicDomain || string.IsNullOrEmpty(requestHost))
            return _domain;

        // Extrair apenas o hostname (sem porta) do request host
        var hostOnly = requestHost.Split(':')[0];
        
        // Retorna o host da requisição com a porta do Jitsi
        return $"{hostOnly}:{_jitsiPort}";
    }

    /// <summary>
    /// Gera um token JWT para autenticação no Jitsi Meet
    /// O token inclui informações do usuário e permissões baseadas no papel
    /// </summary>
    public async Task<JitsiTokenResponseDto?> GenerateTokenAsync(Guid userId, Guid appointmentId, string? requestHost = null)
    {
        if (!_enabled)
            return null;

        // Buscar dados da consulta
        var appointment = await _context.Appointments
            .Include(a => a.Patient)
            .Include(a => a.Professional)
            .Include(a => a.Specialty)
            .FirstOrDefaultAsync(a => a.Id == appointmentId);

        if (appointment == null)
            return null;

        // Buscar dados do usuário
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            return null;

        // Validar acesso: paciente, profissional da consulta, admin ou assistente
        var isPatient = appointment.PatientId == userId;
        var isProfessional = appointment.ProfessionalId == userId;
        var isAdmin = user.Role == UserRole.ADMIN;
        var isAssistant = user.Role == UserRole.ASSISTANT;
        
        if (!isPatient && !isProfessional && !isAdmin && !isAssistant)
            return null;

        // Profissional e Admin são moderadores
        // Assistente NÃO é moderador (atua em nome do paciente)
        var isModerator = isProfessional || isAdmin;

        // Nome da sala: apenas o GUID sem prefixo (mais curto na URL)
        var roomName = appointmentId.ToString("N");

        // Nome de exibição e avatar
        // Se for ASSISTENTE, usa os dados do PACIENTE (assistente é invisível para o médico)
        string displayName;
        string? avatarUrl;
        string displayEmail;
        
        if (isAssistant)
        {
            // Assistente entra com o nome do paciente
            displayName = $"{appointment.Patient.Name} {appointment.Patient.LastName}".Trim();
            avatarUrl = appointment.Patient.Avatar;
            displayEmail = appointment.Patient.Email;
        }
        else
        {
            displayName = $"{user.Name} {user.LastName}".Trim();
            avatarUrl = user.Avatar;
            displayEmail = user.Email;
        }

        // Gerar token JWT para o Jitsi
        var token = GenerateJitsiJwt(
            userId: userId.ToString(),
            email: displayEmail,
            displayName: displayName,
            avatarUrl: avatarUrl,
            roomName: roomName,
            isModerator: isModerator
        );

        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(_tokenExpirationMinutes).ToUnixTimeSeconds();

        // Resolver domínio dinamicamente baseado no host da requisição
        var resolvedDomain = ResolveDomain(requestHost);

        // Nome da sala para servidor público (prefixado para evitar colisões)
        // Usa um prefixo único + ID do agendamento
        var publicRoomName = $"telecuidar-{roomName}";

        return new JitsiTokenResponseDto
        {
            Token = token,
            RoomName = roomName,
            Domain = resolvedDomain,
            PublicDomain = "meet.jit.si",
            PublicRoomName = publicRoomName,
            DisplayName = displayName,
            Email = displayEmail,
            AvatarUrl = avatarUrl,
            IsModerator = isModerator,
            ExpiresAt = expiresAt
        };
    }

    /// <summary>
    /// Obtém as configurações do Jitsi para o frontend
    /// </summary>
    public JitsiConfigDto GetConfig(string? requestHost = null)
    {
        return new JitsiConfigDto
        {
            Enabled = _enabled,
            Domain = ResolveDomain(requestHost),
            RequiresAuth = _requiresAuth
        };
    }

    /// <summary>
    /// Valida se um usuário tem acesso a uma sala de consulta
    /// </summary>
    public async Task<bool> ValidateAccessAsync(Guid userId, Guid appointmentId)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(a => a.Id == appointmentId);

        if (appointment == null)
            return false;

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            return false;

        // Verificar se é participante da consulta, admin ou assistente
        return appointment.PatientId == userId 
            || appointment.ProfessionalId == userId 
            || user.Role == UserRole.ADMIN
            || user.Role == UserRole.ASSISTANT;
    }

    /// <summary>
    /// Gera o token JWT no formato esperado pelo Jitsi Meet
    /// Compatível com prosody-jwt-auth e jitsi-meet-web
    /// 
    /// OTIMIZAÇÃO MÁXIMA: Apenas claims obrigatórios do Prosody JWT:
    /// - iss, aud: autenticação
    /// - iat, exp: validade
    /// - room: restrição de sala
    /// - context.user.name: nome exibido
    /// - moderator: permissões
    /// </summary>
    private string GenerateJitsiJwt(
        string userId,
        string email,
        string displayName,
        string? avatarUrl,
        string roomName,
        bool isModerator)
    {
        if (string.IsNullOrEmpty(_appSecret))
        {
            Console.WriteLine("⚠️ JITSI: AppSecret está vazio! Token não será gerado.");
            return "";
        }

        Console.WriteLine($"🔐 JITSI: Gerando token - AppId: {_appId}, Room: {roomName}, User: {displayName}");

        var now = DateTimeOffset.UtcNow;
        var exp = now.AddMinutes(_tokenExpirationMinutes);

        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_appSecret));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        // Payload mínimo do Jitsi JWT
        var header = new JwtHeader(credentials);
        var payload = new JwtPayload
        {
            { "iss", _appId },
            { "aud", _appId },
            { "iat", now.ToUnixTimeSeconds() },
            { "exp", exp.ToUnixTimeSeconds() },
            { "room", roomName },
            { "context", new Dictionary<string, object>
                {
                    { "user", new Dictionary<string, object>
                        {
                            { "name", displayName },
                            { "moderator", isModerator }
                        }
                    }
                }
            },
            { "moderator", isModerator }
        };

        var token = new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(header, payload));
        Console.WriteLine($"✅ JITSI: Token gerado com sucesso (tamanho: {token.Length} caracteres)");
        return token;
    }
}
