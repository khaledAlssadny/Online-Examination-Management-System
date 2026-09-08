using ITI.ExaminationSystem.Application.Errors;
using Microsoft.AspNetCore.Mvc;

namespace ITI.ExaminationSystem.API.Errors;

public static class ProblemDetailsMapper
{
    public static ProblemDetails Map(ApplicationError error, string traceId)
    {
        ProblemDetails details = new()
        {
            Status = Status(error.Kind),
            Title = Title(error.Kind),
            Detail = SafeDetail(error)
        };

        details.Extensions["code"] = error.Code;
        details.Extensions["traceId"] = traceId;
        if (error.FieldErrors.Count > 0)
            details.Extensions["errors"] = error.FieldErrors;

        return details;
    }

    private static int Status(ApplicationErrorKind kind) => kind switch
    {
        ApplicationErrorKind.Validation => StatusCodes.Status400BadRequest,
        ApplicationErrorKind.Unauthenticated => StatusCodes.Status401Unauthorized,
        ApplicationErrorKind.Forbidden or ApplicationErrorKind.IdentityLinkInvalid or ApplicationErrorKind.RoleMismatch => StatusCodes.Status403Forbidden,
        ApplicationErrorKind.NotFound => StatusCodes.Status404NotFound,
        ApplicationErrorKind.Conflict or ApplicationErrorKind.IntegrityConflict => StatusCodes.Status409Conflict,
        ApplicationErrorKind.Cancellation => 499,
        ApplicationErrorKind.UnexpectedInfrastructureFailure => StatusCodes.Status500InternalServerError,
        _ => StatusCodes.Status500InternalServerError
    };

    private static string Title(ApplicationErrorKind kind) => kind switch
    {
        ApplicationErrorKind.Validation => "Validation failed",
        ApplicationErrorKind.Unauthenticated => "Authentication required",
        ApplicationErrorKind.Forbidden or ApplicationErrorKind.IdentityLinkInvalid or ApplicationErrorKind.RoleMismatch => "Access forbidden",
        ApplicationErrorKind.NotFound => "Resource not found",
        ApplicationErrorKind.Conflict or ApplicationErrorKind.IntegrityConflict => "Conflict",
        ApplicationErrorKind.Cancellation => "Request cancelled",
        _ => "Unexpected error"
    };

    private static string SafeDetail(ApplicationError error) =>
        error.Kind == ApplicationErrorKind.UnexpectedInfrastructureFailure
            ? "An unexpected error occurred."
            : error.Message;
}
