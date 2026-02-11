using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Application.DTOs.AI;
using Application.Interfaces;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Services;

public class AIService : IAIService
{
    private readonly ApplicationDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _apiUrl;
    private readonly string _model;

    public AIService(ApplicationDbContext context)
    {
        _context = context;
        _httpClient = new HttpClient();
        _httpClient.Timeout = TimeSpan.FromSeconds(120);
        
        _apiKey = Environment.GetEnvironmentVariable("AI_API_KEY") ?? "";
        _apiUrl = Environment.GetEnvironmentVariable("AI_API_URL") ?? "https://api.openai.com/v1/chat/completions";
        _model = Environment.GetEnvironmentVariable("AI_MODEL") ?? "gpt-4o-mini";
        
        if (!string.IsNullOrEmpty(_apiKey))
        {
            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _apiKey);
        }
    }

    public async Task<AISummaryResponseDto> GenerateSummaryAsync(GenerateSummaryRequestDto request)
    {
        var prompt = BuildSummaryPrompt(request);
        var response = await CallAIAPIAsync(prompt);
        
        // Save the summary to the appointment
        await SaveSummaryToAppointment(request.AppointmentId, response);
        
        return new AISummaryResponseDto
        {
            Summary = response,
            GeneratedAt = DateTime.UtcNow
        };
    }

    public async Task<AIDiagnosisResponseDto> GenerateDiagnosticHypothesisAsync(GenerateDiagnosisRequestDto request)
    {
        var prompt = BuildDiagnosisPrompt(request);
        var response = await CallAIAPIAsync(prompt);
        
        // Save the diagnosis to the appointment
        await SaveDiagnosisToAppointment(request.AppointmentId, response);
        
        return new AIDiagnosisResponseDto
        {
            DiagnosticHypothesis = response,
            GeneratedAt = DateTime.UtcNow
        };
    }

    public async Task<AIDataDto?> GetAIDataAsync(Guid appointmentId)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null) return null;

        return new AIDataDto
        {
            Summary = appointment.AISummary,
            SummaryGeneratedAt = appointment.AISummaryGeneratedAt,
            DiagnosticHypothesis = appointment.AIDiagnosticHypothesis,
            DiagnosisGeneratedAt = appointment.AIDiagnosisGeneratedAt
        };
    }

    public async Task<bool> SaveAIDataAsync(Guid appointmentId, SaveAIDataDto data)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null) return false;

        if (data.Summary != null)
        {
            appointment.AISummary = data.Summary;
            appointment.AISummaryGeneratedAt = DateTime.UtcNow;
        }

        if (data.DiagnosticHypothesis != null)
        {
            appointment.AIDiagnosticHypothesis = data.DiagnosticHypothesis;
            appointment.AIDiagnosisGeneratedAt = DateTime.UtcNow;
        }

        appointment.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<AnalyzeVitalsResponseDto> AnalyzeVitalsAsync(AnalyzeVitalsRequestDto request)
    {
        var prompt = BuildVitalsAnalysisPrompt(request);
        var response = await CallAIAPIAsync(prompt);
        
        return new AnalyzeVitalsResponseDto
        {
            Analysis = response,
            GeneratedAt = DateTime.UtcNow
        };
    }

    private string BuildVitalsAnalysisPrompt(AnalyzeVitalsRequestDto request)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Analise os seguintes SINAIS VITAIS de um paciente e forneça uma avaliação clínica concisa:");
        sb.AppendLine();

        // Dados demográficos do paciente
        if (!string.IsNullOrEmpty(request.PatientName))
            sb.AppendLine($"Paciente: {request.PatientName}");
        if (request.PatientAge.HasValue)
            sb.AppendLine($"Idade: {request.PatientAge} anos");
        if (!string.IsNullOrEmpty(request.PatientGender))
        {
            var genderLabel = request.PatientGender switch
            {
                "M" => "Masculino",
                "F" => "Feminino",
                "O" => "Outro",
                _ => request.PatientGender
            };
            sb.AppendLine($"Sexo: {genderLabel}");
        }
        sb.AppendLine();

        sb.AppendLine("=== SINAIS VITAIS ===");
        var bio = request.Biometrics;
        if (bio != null)
        {
            if (bio.OxygenSaturation.HasValue)
                sb.AppendLine($"SpO₂: {bio.OxygenSaturation}%");
            if (bio.HeartRate.HasValue)
                sb.AppendLine($"Frequência Cardíaca: {bio.HeartRate} bpm");
            if (bio.BloodPressureSystolic.HasValue && bio.BloodPressureDiastolic.HasValue)
                sb.AppendLine($"Pressão Arterial: {bio.BloodPressureSystolic}/{bio.BloodPressureDiastolic} mmHg");
            if (bio.Temperature.HasValue)
                sb.AppendLine($"Temperatura: {bio.Temperature}°C");
            if (bio.RespiratoryRate.HasValue)
                sb.AppendLine($"Frequência Respiratória: {bio.RespiratoryRate} rpm");
            if (bio.Weight.HasValue)
                sb.AppendLine($"Peso: {bio.Weight} kg");
            if (bio.Height.HasValue)
                sb.AppendLine($"Altura: {bio.Height} cm");
            if (bio.Weight.HasValue && bio.Height.HasValue && bio.Height > 0)
            {
                var heightM = bio.Height.Value / 100m;
                var imc = bio.Weight.Value / (heightM * heightM);
                sb.AppendLine($"IMC calculado: {imc:F1} kg/m²");
            }
            if (bio.Glucose.HasValue)
                sb.AppendLine($"Glicemia: {bio.Glucose} mg/dL");
        }

        sb.AppendLine();
        sb.AppendLine(@"Por favor, forneça uma análise médica CONCISA (máximo 200 palavras) incluindo:
1. **Resumo Geral**: Avaliação geral dos sinais vitais
2. **Alertas**: Valores fora da normalidade que requerem atenção (se houver)
3. **IMC**: Classificação e considerações (se peso e altura disponíveis)
4. **Recomendações**: Sugestões breves para o médico

IMPORTANTE: Esta é uma análise de apoio. O médico responsável deve validar todas as conclusões.");

        return sb.ToString();
    }

    private async Task SaveSummaryToAppointment(Guid appointmentId, string summary)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment != null)
        {
            appointment.AISummary = summary;
            appointment.AISummaryGeneratedAt = DateTime.UtcNow;
            appointment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }

    private async Task SaveDiagnosisToAppointment(Guid appointmentId, string diagnosis)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment != null)
        {
            appointment.AIDiagnosticHypothesis = diagnosis;
            appointment.AIDiagnosisGeneratedAt = DateTime.UtcNow;
            appointment.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }

    private async Task<string> CallAIAPIAsync(string prompt)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            throw new InvalidOperationException("AI API key not configured. Please set AI_API_KEY in the .env file.");
        }

        var requestBody = new
        {
            model = _model,
            messages = new[]
            {
                new { role = "system", content = GetSystemPrompt() },
                new { role = "user", content = prompt }
            },
            temperature = 0.7,
            max_tokens = 2000
        };

        var json = JsonSerializer.Serialize(requestBody);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        try
        {
            var response = await _httpClient.PostAsync(_apiUrl, content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException($"OpenAI API error: {response.StatusCode} - {responseContent}");
            }

            using var doc = JsonDocument.Parse(responseContent);
            var message = doc.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            return message ?? "Não foi possível gerar a resposta.";
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Error calling OpenAI API: {ex.Message}", ex);
        }
    }

    private string GetSystemPrompt()
    {
        return @"Você é um assistente médico especializado em teleconsultas. Sua função é auxiliar profissionais de saúde 
na análise de dados clínicos e elaboração de resumos médicos. 

IMPORTANTE:
- Suas respostas devem ser claras, objetivas e em português brasileiro.
- Você NÃO está fazendo diagnóstico - você está auxiliando o profissional de saúde com análise de dados.
- Sempre indique que as conclusões devem ser validadas pelo profissional de saúde.
- Utilize terminologia médica apropriada.
- Mantenha um tom profissional e ético.
- Não invente informações - baseie-se apenas nos dados fornecidos.";
    }

    private string BuildSummaryPrompt(GenerateSummaryRequestDto request)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Por favor, gere um RESUMO CLÍNICO completo e estruturado com base nos seguintes dados da consulta:");
        sb.AppendLine();

        if (request.PatientData != null)
        {
            sb.AppendLine("=== DADOS DO PACIENTE ===");
            if (!string.IsNullOrEmpty(request.PatientData.Name))
                sb.AppendLine($"Nome: {request.PatientData.Name}");
            if (!string.IsNullOrEmpty(request.PatientData.BirthDate))
            {
                sb.AppendLine($"Data de Nascimento: {request.PatientData.BirthDate}");
                // Calcular e incluir a idade
                var age = CalculateAge(request.PatientData.BirthDate);
                if (age.HasValue)
                    sb.AppendLine($"Idade: {age} anos");
            }
            if (!string.IsNullOrEmpty(request.PatientData.Gender))
            {
                var genderLabel = request.PatientData.Gender switch
                {
                    "M" => "Masculino",
                    "F" => "Feminino",
                    "O" => "Outro",
                    _ => request.PatientData.Gender
                };
                sb.AppendLine($"Sexo: {genderLabel}");
            }
            if (!string.IsNullOrEmpty(request.PatientData.BloodType))
                sb.AppendLine($"Tipo Sanguíneo: {request.PatientData.BloodType}");
            sb.AppendLine();
        }

        if (request.PreConsultationData != null)
        {
            sb.AppendLine("=== DADOS DA PRÉ-CONSULTA ===");
            if (request.PreConsultationData.PersonalInfo != null)
            {
                var pi = request.PreConsultationData.PersonalInfo;
                if (!string.IsNullOrEmpty(pi.Weight))
                    sb.AppendLine($"Peso: {pi.Weight}");
                if (!string.IsNullOrEmpty(pi.Height))
                    sb.AppendLine($"Altura: {pi.Height}");
            }
            if (request.PreConsultationData.MedicalHistory != null)
            {
                var mh = request.PreConsultationData.MedicalHistory;
                sb.AppendLine("Histórico Médico:");
                if (!string.IsNullOrEmpty(mh.ChronicConditions))
                    sb.AppendLine($"  - Condições Crônicas: {mh.ChronicConditions}");
                if (!string.IsNullOrEmpty(mh.Medications))
                    sb.AppendLine($"  - Medicações: {mh.Medications}");
                if (!string.IsNullOrEmpty(mh.Allergies))
                    sb.AppendLine($"  - Alergias: {mh.Allergies}");
                if (!string.IsNullOrEmpty(mh.Surgeries))
                    sb.AppendLine($"  - Cirurgias: {mh.Surgeries}");
            }
            if (request.PreConsultationData.CurrentSymptoms != null)
            {
                var cs = request.PreConsultationData.CurrentSymptoms;
                sb.AppendLine("Sintomas Atuais:");
                if (!string.IsNullOrEmpty(cs.MainSymptoms))
                    sb.AppendLine($"  - Sintomas Principais: {cs.MainSymptoms}");
                if (!string.IsNullOrEmpty(cs.SymptomOnset))
                    sb.AppendLine($"  - Início dos Sintomas: {cs.SymptomOnset}");
                if (cs.PainIntensity.HasValue)
                    sb.AppendLine($"  - Intensidade da Dor: {cs.PainIntensity}/10");
            }
            sb.AppendLine();
        }

        if (request.AnamnesisData != null)
        {
            sb.AppendLine("=== ANAMNESE ===");
            if (!string.IsNullOrEmpty(request.AnamnesisData.ChiefComplaint))
                sb.AppendLine($"Queixa Principal: {request.AnamnesisData.ChiefComplaint}");
            if (!string.IsNullOrEmpty(request.AnamnesisData.PresentIllnessHistory))
                sb.AppendLine($"História da Doença Atual: {request.AnamnesisData.PresentIllnessHistory}");
            
            // Antecedentes Pessoais
            if (request.AnamnesisData.PersonalHistory != null)
            {
                var ph = request.AnamnesisData.PersonalHistory;
                sb.AppendLine("Antecedentes Pessoais:");
                if (!string.IsNullOrEmpty(ph.PreviousDiseases))
                    sb.AppendLine($"  - Doenças Anteriores: {ph.PreviousDiseases}");
                if (!string.IsNullOrEmpty(ph.Surgeries))
                    sb.AppendLine($"  - Cirurgias: {ph.Surgeries}");
                if (!string.IsNullOrEmpty(ph.Hospitalizations))
                    sb.AppendLine($"  - Internações: {ph.Hospitalizations}");
                if (!string.IsNullOrEmpty(ph.Allergies))
                    sb.AppendLine($"  - Alergias: {ph.Allergies}");
                if (!string.IsNullOrEmpty(ph.CurrentMedications))
                    sb.AppendLine($"  - Medicações em Uso: {ph.CurrentMedications}");
                if (!string.IsNullOrEmpty(ph.Vaccinations))
                    sb.AppendLine($"  - Vacinação: {ph.Vaccinations}");
            }
            
            if (!string.IsNullOrEmpty(request.AnamnesisData.FamilyHistory))
                sb.AppendLine($"Histórico Familiar: {request.AnamnesisData.FamilyHistory}");
            
            // Hábitos de Vida
            if (request.AnamnesisData.Lifestyle != null)
            {
                var ls = request.AnamnesisData.Lifestyle;
                sb.AppendLine("Hábitos de Vida:");
                if (!string.IsNullOrEmpty(ls.Diet))
                    sb.AppendLine($"  - Alimentação: {ls.Diet}");
                if (!string.IsNullOrEmpty(ls.PhysicalActivity))
                    sb.AppendLine($"  - Atividade Física: {ls.PhysicalActivity}");
                if (!string.IsNullOrEmpty(ls.Smoking))
                    sb.AppendLine($"  - Tabagismo: {ls.Smoking}");
                if (!string.IsNullOrEmpty(ls.Alcohol))
                    sb.AppendLine($"  - Etilismo: {ls.Alcohol}");
                if (!string.IsNullOrEmpty(ls.Drugs))
                    sb.AppendLine($"  - Uso de Drogas: {ls.Drugs}");
                if (!string.IsNullOrEmpty(ls.Sleep))
                    sb.AppendLine($"  - Sono: {ls.Sleep}");
            }
            
            // Revisão de Sistemas
            if (request.AnamnesisData.SystemsReview != null)
            {
                var sr = request.AnamnesisData.SystemsReview;
                sb.AppendLine("Revisão de Sistemas:");
                if (!string.IsNullOrEmpty(sr.Cardiovascular))
                    sb.AppendLine($"  - Cardiovascular: {sr.Cardiovascular}");
                if (!string.IsNullOrEmpty(sr.Respiratory))
                    sb.AppendLine($"  - Respiratório: {sr.Respiratory}");
                if (!string.IsNullOrEmpty(sr.Gastrointestinal))
                    sb.AppendLine($"  - Gastrointestinal: {sr.Gastrointestinal}");
                if (!string.IsNullOrEmpty(sr.Genitourinary))
                    sb.AppendLine($"  - Geniturinário: {sr.Genitourinary}");
                if (!string.IsNullOrEmpty(sr.Musculoskeletal))
                    sb.AppendLine($"  - Musculoesquelético: {sr.Musculoskeletal}");
                if (!string.IsNullOrEmpty(sr.Neurological))
                    sb.AppendLine($"  - Neurológico: {sr.Neurological}");
                if (!string.IsNullOrEmpty(sr.Psychiatric))
                    sb.AppendLine($"  - Psiquiátrico: {sr.Psychiatric}");
                if (!string.IsNullOrEmpty(sr.Endocrine))
                    sb.AppendLine($"  - Endócrino: {sr.Endocrine}");
                if (!string.IsNullOrEmpty(sr.Hematologic))
                    sb.AppendLine($"  - Hematológico: {sr.Hematologic}");
            }
            
            if (!string.IsNullOrEmpty(request.AnamnesisData.AdditionalNotes))
                sb.AppendLine($"Observações Adicionais: {request.AnamnesisData.AdditionalNotes}");
                
            sb.AppendLine();
        }

        if (request.BiometricsData != null)
        {
            sb.AppendLine("=== DADOS BIOMÉTRICOS / SINAIS VITAIS ===");
            if (request.BiometricsData.HeartRate.HasValue)
                sb.AppendLine($"Frequência Cardíaca: {request.BiometricsData.HeartRate} bpm");
            if (request.BiometricsData.BloodPressureSystolic.HasValue && request.BiometricsData.BloodPressureDiastolic.HasValue)
                sb.AppendLine($"Pressão Arterial: {request.BiometricsData.BloodPressureSystolic}/{request.BiometricsData.BloodPressureDiastolic} mmHg");
            if (request.BiometricsData.OxygenSaturation.HasValue)
                sb.AppendLine($"Saturação de Oxigênio: {request.BiometricsData.OxygenSaturation}%");
            if (request.BiometricsData.Temperature.HasValue)
                sb.AppendLine($"Temperatura: {request.BiometricsData.Temperature}°C");
            if (request.BiometricsData.RespiratoryRate.HasValue)
                sb.AppendLine($"Frequência Respiratória: {request.BiometricsData.RespiratoryRate} rpm");
            if (request.BiometricsData.Glucose.HasValue)
                sb.AppendLine($"Glicemia: {request.BiometricsData.Glucose} mg/dL");
            if (request.BiometricsData.Weight.HasValue)
                sb.AppendLine($"Peso: {request.BiometricsData.Weight} kg");
            if (request.BiometricsData.Height.HasValue)
                sb.AppendLine($"Altura: {request.BiometricsData.Height} cm");
            if (request.BiometricsData.Weight.HasValue && request.BiometricsData.Height.HasValue && request.BiometricsData.Height > 0)
            {
                var heightM = request.BiometricsData.Height.Value / 100m;
                var imc = request.BiometricsData.Weight.Value / (heightM * heightM);
                sb.AppendLine($"IMC calculado: {imc:F1} kg/m²");
            }
            sb.AppendLine();
        }

        if (request.SoapData != null)
        {
            sb.AppendLine("=== NOTAS SOAP ===");
            if (!string.IsNullOrEmpty(request.SoapData.Subjective))
                sb.AppendLine($"Subjetivo: {request.SoapData.Subjective}");
            if (!string.IsNullOrEmpty(request.SoapData.Objective))
                sb.AppendLine($"Objetivo: {request.SoapData.Objective}");
            if (!string.IsNullOrEmpty(request.SoapData.Assessment))
                sb.AppendLine($"Avaliação: {request.SoapData.Assessment}");
            if (!string.IsNullOrEmpty(request.SoapData.Plan))
                sb.AppendLine($"Plano: {request.SoapData.Plan}");
            sb.AppendLine();
        }

        if (request.SpecialtyFieldsData != null)
        {
            sb.AppendLine($"=== CAMPOS DA ESPECIALIDADE ({request.SpecialtyFieldsData.SpecialtyName ?? "N/A"}) ===");
            if (request.SpecialtyFieldsData.CustomFields != null)
            {
                foreach (var field in request.SpecialtyFieldsData.CustomFields)
                {
                    sb.AppendLine($"{field.Key}: {field.Value}");
                }
            }
            sb.AppendLine();
        }

        sb.AppendLine("Por favor, gere um RESUMO CLÍNICO ESTRUTURADO incluindo OBRIGATORIAMENTE:");
        sb.AppendLine("1. **Identificação do Paciente**: Nome, idade, sexo");
        sb.AppendLine("2. **Dados Antropométricos**: Peso, altura e IMC (se disponíveis)");
        sb.AppendLine("3. **Sinais Vitais**: FC, PA, SpO₂, temperatura, FR, glicemia (listar os valores informados)");
        sb.AppendLine("4. **Motivo da Consulta / Queixa Principal**");
        sb.AppendLine("5. **Histórico Relevante**: Antecedentes pessoais e familiares pertinentes");
        sb.AppendLine("6. **Avaliação Clínica**: Análise dos dados apresentados");
        sb.AppendLine("7. **Pontos de Atenção**: Alertas ou valores fora da normalidade identificados");
        sb.AppendLine();
        sb.AppendLine("IMPORTANTE: Inclua explicitamente os valores dos sinais vitais e dados antropométricos no resumo para documentar que foram considerados na avaliação.");

        return sb.ToString();
    }

    private string BuildDiagnosisPrompt(GenerateDiagnosisRequestDto request)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Com base nos dados clínicos fornecidos, elabore HIPÓTESES DIAGNÓSTICAS para auxiliar o profissional de saúde:");
        sb.AppendLine();

        // Include the same data as summary
        if (request.PatientData != null)
        {
            sb.AppendLine("=== DADOS DO PACIENTE ===");
            if (!string.IsNullOrEmpty(request.PatientData.Name))
                sb.AppendLine($"Nome: {request.PatientData.Name}");
            if (!string.IsNullOrEmpty(request.PatientData.BirthDate))
            {
                sb.AppendLine($"Data de Nascimento: {request.PatientData.BirthDate}");
                // Calcular e incluir a idade
                var age = CalculateAge(request.PatientData.BirthDate);
                if (age.HasValue)
                    sb.AppendLine($"Idade: {age} anos");
            }
            if (!string.IsNullOrEmpty(request.PatientData.Gender))
            {
                var genderLabel = request.PatientData.Gender switch
                {
                    "M" => "Masculino",
                    "F" => "Feminino",
                    "O" => "Outro",
                    _ => request.PatientData.Gender
                };
                sb.AppendLine($"Sexo: {genderLabel}");
            }
            sb.AppendLine();
        }

        // Incluir peso e altura da pré-consulta
        if (request.PreConsultationData?.PersonalInfo != null)
        {
            var pi = request.PreConsultationData.PersonalInfo;
            if (!string.IsNullOrEmpty(pi.Weight) || !string.IsNullOrEmpty(pi.Height))
            {
                sb.AppendLine("=== DADOS ANTROPOMÉTRICOS ===");
                if (!string.IsNullOrEmpty(pi.Weight))
                    sb.AppendLine($"Peso: {pi.Weight}");
                if (!string.IsNullOrEmpty(pi.Height))
                    sb.AppendLine($"Altura: {pi.Height}");
                sb.AppendLine();
            }
        }

        if (request.PreConsultationData?.CurrentSymptoms != null)
        {
            var cs = request.PreConsultationData.CurrentSymptoms;
            sb.AppendLine("=== SINTOMAS ===");
            if (!string.IsNullOrEmpty(cs.MainSymptoms))
                sb.AppendLine($"Sintomas Principais: {cs.MainSymptoms}");
            if (!string.IsNullOrEmpty(cs.SymptomOnset))
                sb.AppendLine($"Início dos Sintomas: {cs.SymptomOnset}");
            if (cs.PainIntensity.HasValue)
                sb.AppendLine($"Intensidade da Dor: {cs.PainIntensity}/10");
            sb.AppendLine();
        }

        if (request.AnamnesisData != null)
        {
            sb.AppendLine("=== ANAMNESE ===");
            if (!string.IsNullOrEmpty(request.AnamnesisData.ChiefComplaint))
                sb.AppendLine($"Queixa Principal: {request.AnamnesisData.ChiefComplaint}");
            if (!string.IsNullOrEmpty(request.AnamnesisData.PresentIllnessHistory))
                sb.AppendLine($"História da Doença Atual: {request.AnamnesisData.PresentIllnessHistory}");
            
            // Antecedentes Pessoais (relevantes para diagnóstico)
            if (request.AnamnesisData.PersonalHistory != null)
            {
                var ph = request.AnamnesisData.PersonalHistory;
                if (!string.IsNullOrEmpty(ph.PreviousDiseases))
                    sb.AppendLine($"Doenças Anteriores: {ph.PreviousDiseases}");
                if (!string.IsNullOrEmpty(ph.Allergies))
                    sb.AppendLine($"Alergias: {ph.Allergies}");
                if (!string.IsNullOrEmpty(ph.CurrentMedications))
                    sb.AppendLine($"Medicações em Uso: {ph.CurrentMedications}");
            }
            
            if (!string.IsNullOrEmpty(request.AnamnesisData.FamilyHistory))
                sb.AppendLine($"Histórico Familiar: {request.AnamnesisData.FamilyHistory}");
            
            // Revisão de Sistemas (importante para diagnóstico diferencial)
            if (request.AnamnesisData.SystemsReview != null)
            {
                var sr = request.AnamnesisData.SystemsReview;
                var hasSystemsData = !string.IsNullOrEmpty(sr.Cardiovascular) || !string.IsNullOrEmpty(sr.Respiratory) ||
                                     !string.IsNullOrEmpty(sr.Gastrointestinal) || !string.IsNullOrEmpty(sr.Neurological);
                if (hasSystemsData)
                {
                    sb.AppendLine("Revisão de Sistemas:");
                    if (!string.IsNullOrEmpty(sr.Cardiovascular))
                        sb.AppendLine($"  - Cardiovascular: {sr.Cardiovascular}");
                    if (!string.IsNullOrEmpty(sr.Respiratory))
                        sb.AppendLine($"  - Respiratório: {sr.Respiratory}");
                    if (!string.IsNullOrEmpty(sr.Gastrointestinal))
                        sb.AppendLine($"  - Gastrointestinal: {sr.Gastrointestinal}");
                    if (!string.IsNullOrEmpty(sr.Genitourinary))
                        sb.AppendLine($"  - Geniturinário: {sr.Genitourinary}");
                    if (!string.IsNullOrEmpty(sr.Musculoskeletal))
                        sb.AppendLine($"  - Musculoesquelético: {sr.Musculoskeletal}");
                    if (!string.IsNullOrEmpty(sr.Neurological))
                        sb.AppendLine($"  - Neurológico: {sr.Neurological}");
                    if (!string.IsNullOrEmpty(sr.Psychiatric))
                        sb.AppendLine($"  - Psiquiátrico: {sr.Psychiatric}");
                }
            }
            sb.AppendLine();
        }

        if (request.BiometricsData != null)
        {
            sb.AppendLine("=== SINAIS VITAIS E MEDIDAS ===");
            if (request.BiometricsData.HeartRate.HasValue)
                sb.AppendLine($"Frequência Cardíaca: {request.BiometricsData.HeartRate} bpm");
            if (request.BiometricsData.BloodPressureSystolic.HasValue && request.BiometricsData.BloodPressureDiastolic.HasValue)
                sb.AppendLine($"Pressão Arterial: {request.BiometricsData.BloodPressureSystolic}/{request.BiometricsData.BloodPressureDiastolic} mmHg");
            if (request.BiometricsData.OxygenSaturation.HasValue)
                sb.AppendLine($"SpO₂: {request.BiometricsData.OxygenSaturation}%");
            if (request.BiometricsData.Temperature.HasValue)
                sb.AppendLine($"Temperatura: {request.BiometricsData.Temperature}°C");
            if (request.BiometricsData.RespiratoryRate.HasValue)
                sb.AppendLine($"Frequência Respiratória: {request.BiometricsData.RespiratoryRate} rpm");
            if (request.BiometricsData.Glucose.HasValue)
                sb.AppendLine($"Glicemia: {request.BiometricsData.Glucose} mg/dL");
            if (request.BiometricsData.Weight.HasValue)
                sb.AppendLine($"Peso: {request.BiometricsData.Weight} kg");
            if (request.BiometricsData.Height.HasValue)
                sb.AppendLine($"Altura: {request.BiometricsData.Height} cm");
            if (request.BiometricsData.Weight.HasValue && request.BiometricsData.Height.HasValue && request.BiometricsData.Height > 0)
            {
                var heightM = request.BiometricsData.Height.Value / 100m;
                var imc = request.BiometricsData.Weight.Value / (heightM * heightM);
                sb.AppendLine($"IMC calculado: {imc:F1} kg/m²");
            }
            sb.AppendLine();
        }

        if (request.SoapData != null)
        {
            sb.AppendLine("=== NOTAS SOAP ===");
            if (!string.IsNullOrEmpty(request.SoapData.Subjective))
                sb.AppendLine($"Subjetivo: {request.SoapData.Subjective}");
            if (!string.IsNullOrEmpty(request.SoapData.Objective))
                sb.AppendLine($"Objetivo: {request.SoapData.Objective}");
            if (!string.IsNullOrEmpty(request.SoapData.Assessment))
                sb.AppendLine($"Avaliação: {request.SoapData.Assessment}");
            if (!string.IsNullOrEmpty(request.SoapData.Plan))
                sb.AppendLine($"Plano: {request.SoapData.Plan}");
            sb.AppendLine();
        }

        if (request.SpecialtyFieldsData != null && request.SpecialtyFieldsData.CustomFields != null && request.SpecialtyFieldsData.CustomFields.Count > 0)
        {
            sb.AppendLine($"=== CAMPOS DA ESPECIALIDADE ({request.SpecialtyFieldsData.SpecialtyName ?? "N/A"}) ===");
            foreach (var field in request.SpecialtyFieldsData.CustomFields)
            {
                if (!string.IsNullOrEmpty(field.Value))
                    sb.AppendLine($"{field.Key}: {field.Value}");
            }
            sb.AppendLine();
        }

        if (!string.IsNullOrEmpty(request.AdditionalContext))
        {
            sb.AppendLine("=== CONTEXTO ADICIONAL FORNECIDO PELO PROFISSIONAL ===");
            sb.AppendLine(request.AdditionalContext);
            sb.AppendLine();
        }

        sb.AppendLine("Por favor, elabore HIPÓTESES DIAGNÓSTICAS estruturadas incluindo:");
        sb.AppendLine();
        sb.AppendLine("1. **Dados Considerados na Análise**:");
        sb.AppendLine("   - Perfil do paciente (idade, sexo)");
        sb.AppendLine("   - Dados antropométricos (peso, altura, IMC) se disponíveis");
        sb.AppendLine("   - Sinais vitais relevantes (citar valores alterados ou normais)");
        sb.AppendLine();
        sb.AppendLine("2. **Hipótese Diagnóstica Principal**: Diagnóstico mais provável com justificativa baseada nos dados");
        sb.AppendLine();
        sb.AppendLine("3. **Diagnósticos Diferenciais**: Outras possibilidades a considerar");
        sb.AppendLine();
        sb.AppendLine("4. **Correlação com Sinais Vitais**: Como os valores de FC, PA, SpO₂, temperatura, etc. se relacionam com a hipótese");
        sb.AppendLine();
        sb.AppendLine("5. **Exames Complementares Sugeridos** (se aplicável)");
        sb.AppendLine();
        sb.AppendLine("6. **Red Flags / Sinais de Alarme**: Alertas identificados nos dados");
        sb.AppendLine();
        sb.AppendLine("IMPORTANTE: Mencione explicitamente os valores dos sinais vitais e dados antropométricos que fundamentam sua análise.");
        sb.AppendLine();
        sb.AppendLine("NOTA: Estas são sugestões para auxiliar a decisão clínica do profissional de saúde, que deve validar e confirmar os diagnósticos.");

        return sb.ToString();
    }

    /// <summary>
    /// Calcula a idade a partir de uma string de data de nascimento
    /// </summary>
    private int? CalculateAge(string? birthDateString)
    {
        if (string.IsNullOrEmpty(birthDateString))
            return null;

        if (DateTime.TryParse(birthDateString, out var birthDate))
        {
            var today = DateTime.Today;
            var age = today.Year - birthDate.Year;
            if (birthDate.Date > today.AddYears(-age))
                age--;
            return age;
        }

        return null;
    }
}
