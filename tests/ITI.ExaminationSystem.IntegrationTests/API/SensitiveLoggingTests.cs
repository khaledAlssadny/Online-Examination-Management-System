using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace ITI.ExaminationSystem.IntegrationTests.API;

public sealed class SensitiveLoggingTests
{
    [Fact]
    public async Task Request_diagnostics_do_not_capture_credentials_headers_bodies_or_answers()
    {
        CapturingLoggerProvider logs = new();
        await using WebApplicationFactory<Program> factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder => builder.ConfigureServices(services => services.AddLogging(logging =>
            {
                logging.ClearProviders();
                logging.AddProvider(logs);
            })));
        using HttpClient client = factory.CreateClient();
        using HttpRequestMessage request = new(
            HttpMethod.Get,
            "/health/live?password=sentinel-password&legacyCredential=sentinel-legacy" +
            "&signingKey=sentinel-signing-key&sensitiveProfile=sentinel-profile" +
            "&correctAnswer=correct-answer-sentinel&modelAnswer=model-answer-sentinel");
        request.Headers.TryAddWithoutValidation("Authorization", "Bearer sentinel-access-token");
        request.Headers.TryAddWithoutValidation("Cookie", "refreshToken=sentinel-refresh-token");

        using HttpResponseMessage response = await client.SendAsync(request);
        string diagnostics = string.Join(Environment.NewLine, logs.Messages);

        response.EnsureSuccessStatusCode();
        Assert.DoesNotContain("sentinel-password", diagnostics);
        Assert.DoesNotContain("sentinel-legacy", diagnostics);
        Assert.DoesNotContain("sentinel-access-token", diagnostics);
        Assert.DoesNotContain("sentinel-refresh-token", diagnostics);
        Assert.DoesNotContain("sentinel-signing-key", diagnostics);
        Assert.DoesNotContain("sentinel-profile", diagnostics);
        Assert.DoesNotContain("correct-answer-sentinel", diagnostics);
        Assert.DoesNotContain("model-answer-sentinel", diagnostics);
    }

    private sealed class CapturingLoggerProvider : ILoggerProvider
    {
        public List<string> Messages { get; } = [];

        public ILogger CreateLogger(string categoryName) => new CapturingLogger(Messages);

        public void Dispose()
        {
        }
    }

    private sealed class CapturingLogger(ICollection<string> messages) : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter) => messages.Add(formatter(state, exception));
    }
}
