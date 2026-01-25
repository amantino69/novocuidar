using Application.DTOs.AI;

namespace Application.Interfaces;

public interface IAIService
{
    Task<AISummaryResponseDto> GenerateSummaryAsync(GenerateSummaryRequestDto request);
    Task<AIDiagnosisResponseDto> GenerateDiagnosticHypothesisAsync(GenerateDiagnosisRequestDto request);
    Task<AnalyzeVitalsResponseDto> AnalyzeVitalsAsync(AnalyzeVitalsRequestDto request);
    Task<AIDataDto?> GetAIDataAsync(Guid appointmentId);
    Task<bool> SaveAIDataAsync(Guid appointmentId, SaveAIDataDto data);
}
