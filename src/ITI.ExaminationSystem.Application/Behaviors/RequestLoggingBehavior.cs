using System.Diagnostics;
using ITI.ExaminationSystem.Application.Abstractions.Diagnostics;
using MediatR;

namespace ITI.ExaminationSystem.Application.Behaviors;

public sealed class RequestLoggingBehavior<TRequest, TResponse>(IRequestDiagnostics diagnostics)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        long startedAt = Stopwatch.GetTimestamp();
        string outcome = "Failed";

        try
        {
            TResponse response = await next(cancellationToken);
            outcome = "Succeeded";
            return response;
        }
        catch (OperationCanceledException)
        {
            outcome = "Cancelled";
            throw;
        }
        finally
        {
            long elapsedMilliseconds = (long)Stopwatch.GetElapsedTime(startedAt).TotalMilliseconds;
            diagnostics.RequestCompleted(typeof(TRequest).Name, outcome, elapsedMilliseconds);
        }
    }
}
