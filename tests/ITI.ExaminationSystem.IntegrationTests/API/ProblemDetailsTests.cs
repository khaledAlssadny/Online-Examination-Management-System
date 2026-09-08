using ITI.ExaminationSystem.API.Errors;
using ITI.ExaminationSystem.API.Middleware;
using ITI.ExaminationSystem.Application.Errors;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;

namespace ITI.ExaminationSystem.IntegrationTests.API;

public sealed class ProblemDetailsTests
{
    public static TheoryData<ApplicationError, int> Mappings => new()
    {
        { ApplicationError.Validation(new Dictionary<string, IReadOnlyList<string>> { ["Name"] = ["Required."] }), 400 },
        { new(ApplicationErrorCodes.Unauthenticated, ApplicationErrorKind.Unauthenticated, "Authentication is required."), 401 },
        { new(ApplicationErrorCodes.Forbidden, ApplicationErrorKind.Forbidden, "Access is forbidden."), 403 },
        { new(ApplicationErrorCodes.RoleMismatch, ApplicationErrorKind.RoleMismatch, "Actor role is invalid."), 403 },
        { new(ApplicationErrorCodes.IdentityLinkInvalid, ApplicationErrorKind.IdentityLinkInvalid, "Actor link is invalid."), 403 },
        { new(ApplicationErrorCodes.NotFound, ApplicationErrorKind.NotFound, "Resource was not found."), 404 },
        { new(ApplicationErrorCodes.Conflict, ApplicationErrorKind.Conflict, "A conflict occurred."), 409 },
        { new(ApplicationErrorCodes.IntegrityConflict, ApplicationErrorKind.IntegrityConflict, "Integrity conflict."), 409 },
        { new(ApplicationErrorCodes.Cancelled, ApplicationErrorKind.Cancellation, "Request was cancelled."), 499 },
        { new(ApplicationErrorCodes.UnexpectedFailure, ApplicationErrorKind.UnexpectedInfrastructureFailure, "Unexpected failure."), 500 }
    };

    [Theory]
    [MemberData(nameof(Mappings))]
    public void Application_errors_map_to_approved_problem_details_statuses(ApplicationError error, int status)
    {
        ProblemDetails details = ProblemDetailsMapper.Map(error, "trace-123");

        Assert.Equal(status, details.Status);
        Assert.Equal(error.Code, details.Extensions["code"]);
        Assert.Equal("trace-123", details.Extensions["traceId"]);
    }

    [Fact]
    public void Validation_problem_details_include_safe_structured_field_errors()
    {
        ApplicationError error = ApplicationError.Validation(
            new Dictionary<string, IReadOnlyList<string>> { ["Password"] = ["Password is required."] });

        ProblemDetails details = ProblemDetailsMapper.Map(error, "trace-456");

        Assert.Equal(400, details.Status);
        Assert.Equal(error.FieldErrors, details.Extensions["errors"]);
        Assert.DoesNotContain("secret-value", System.Text.Json.JsonSerializer.Serialize(details));
    }

    [Fact]
    public void Unexpected_error_detail_is_replaced_with_safe_generic_content()
    {
        ApplicationError error = new(
            ApplicationErrorCodes.UnexpectedFailure,
            ApplicationErrorKind.UnexpectedInfrastructureFailure,
            "connection string password=secret-value");

        ProblemDetails details = ProblemDetailsMapper.Map(error, "trace-safe");

        Assert.Equal("An unexpected error occurred.", details.Detail);
        Assert.DoesNotContain("secret-value", System.Text.Json.JsonSerializer.Serialize(details));
    }

    [Fact]
    public async Task Unexpected_exception_returns_safe_generic_problem_details()
    {
        DefaultHttpContext context = CreateContext();
        GlobalExceptionHandler handler = new(NullLogger<GlobalExceptionHandler>.Instance);

        bool handled = await handler.TryHandleAsync(
            context,
            new InvalidOperationException("database password=secret-value and stack internals"),
            CancellationToken.None);
        string body = await ReadBody(context.Response);

        Assert.True(handled);
        Assert.Equal(500, context.Response.StatusCode);
        Assert.Contains("UnexpectedFailure", body);
        Assert.DoesNotContain("secret-value", body);
        Assert.DoesNotContain("InvalidOperationException", body);
    }

    [Fact]
    public async Task Representable_cancellation_returns_499_instead_of_500()
    {
        DefaultHttpContext context = CreateContext();
        GlobalExceptionHandler handler = new(NullLogger<GlobalExceptionHandler>.Instance);

        bool handled = await handler.TryHandleAsync(
            context,
            new OperationCanceledException(),
            CancellationToken.None);

        Assert.True(handled);
        Assert.Equal(499, context.Response.StatusCode);
    }

    private static DefaultHttpContext CreateContext()
    {
        DefaultHttpContext context = new();
        context.TraceIdentifier = "trace-test";
        context.Response.Body = new MemoryStream();
        return context;
    }

    private static async Task<string> ReadBody(HttpResponse response)
    {
        response.Body.Position = 0;
        using StreamReader reader = new(response.Body);
        return await reader.ReadToEndAsync();
    }
}
