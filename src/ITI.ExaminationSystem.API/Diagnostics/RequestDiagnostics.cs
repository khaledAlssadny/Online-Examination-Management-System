using ITI.ExaminationSystem.Application.Abstractions.Diagnostics;

namespace ITI.ExaminationSystem.API.Diagnostics;

internal sealed class RequestDiagnostics(ILogger<RequestDiagnostics> logger) : IRequestDiagnostics
{
    public void RequestCompleted(string operationName, string outcome, long elapsedMilliseconds) =>
        logger.LogInformation(
            "Application request {OperationName} completed with {Outcome} in {ElapsedMilliseconds} ms.",
            operationName,
            outcome,
            elapsedMilliseconds);
}
