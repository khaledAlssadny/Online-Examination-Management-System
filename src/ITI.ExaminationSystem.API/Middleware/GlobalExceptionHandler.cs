using ITI.ExaminationSystem.API.Errors;
using ITI.ExaminationSystem.Application.Errors;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace ITI.ExaminationSystem.API.Middleware;

public sealed class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is OperationCanceledException && httpContext.RequestAborted.IsCancellationRequested)
            return false;

        ApplicationError error = ToApplicationError(exception);
        ProblemDetails details = ProblemDetailsMapper.Map(error, httpContext.TraceIdentifier);

        logger.LogError("Request failed with application code {ApplicationCode} and trace {TraceId}.", error.Code, httpContext.TraceIdentifier);
        httpContext.Response.StatusCode = details.Status!.Value;
        await httpContext.Response.WriteAsJsonAsync(
            details,
            options: null,
            contentType: "application/problem+json",
            cancellationToken);

        return true;
    }

    private static ApplicationError ToApplicationError(Exception exception) => exception switch
    {
        ApplicationErrorException applicationException => applicationException.Error,
        OperationCanceledException => new(
            ApplicationErrorCodes.Cancelled,
            ApplicationErrorKind.Cancellation,
            "The request was cancelled."),
        _ => new(
            ApplicationErrorCodes.UnexpectedFailure,
            ApplicationErrorKind.UnexpectedInfrastructureFailure,
            "An unexpected error occurred.")
    };
}
