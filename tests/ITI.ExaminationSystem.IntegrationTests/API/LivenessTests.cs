using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace ITI.ExaminationSystem.IntegrationTests.API;

public sealed class LivenessTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;

    public LivenessTests(WebApplicationFactory<Program> factory) => client = factory.CreateClient();

    [Fact]
    public async Task Anonymous_liveness_request_matches_the_approved_contract()
    {
        using HttpResponseMessage response = await client.GetAsync("/health/live");
        LivenessResponse? body = await response.Content.ReadFromJsonAsync<LivenessResponse>();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("live", body?.Status);
        Assert.Equal("application/json", response.Content.Headers.ContentType?.MediaType);
    }

    private sealed record LivenessResponse(string Status);
}
