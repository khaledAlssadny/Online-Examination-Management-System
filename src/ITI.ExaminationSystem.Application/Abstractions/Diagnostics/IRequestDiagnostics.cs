namespace ITI.ExaminationSystem.Application.Abstractions.Diagnostics;

public interface IRequestDiagnostics
{
    void RequestCompleted(string operationName, string outcome, long elapsedMilliseconds);
}
