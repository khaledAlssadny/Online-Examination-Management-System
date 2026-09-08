namespace ITI.ExaminationSystem.API.Endpoints;

internal static class SystemEndpoints
{
    public static IEndpointRouteBuilder MapSystemEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints
            .MapGet("/health/live", () => Results.Ok(new LivenessResponse("live")))
            .AllowAnonymous();

        return endpoints;
    }

    private sealed record LivenessResponse(string Status);
}
