using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace ITI.ExaminationSystem.IntegrationTests.Infrastructure;

public sealed class Phase0AIsolationTests
{
    [Fact]
    public async Task Api_starts_without_external_or_authentication_configuration()
    {
        await using WebApplicationFactory<Program> factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder => builder.ConfigureAppConfiguration((_, configuration) =>
                configuration.Sources.Clear()));
        using HttpClient client = factory.CreateClient();

        using HttpResponseMessage response = await client.GetAsync("/health/live");

        response.EnsureSuccessStatusCode();
    }

    [Fact]
    public void Production_configuration_contains_no_connection_or_credential_settings()
    {
        string apiRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../src/ITI.ExaminationSystem.API"));
        string[] configurationFiles =
        [
            Path.Combine(apiRoot, "appsettings.json"),
            Path.Combine(apiRoot, "appsettings.Development.json"),
            Path.Combine(apiRoot, "Properties/launchSettings.json")
        ];
        string[] forbiddenKeys =
        [
            "ConnectionStrings", "Password", "Token", "Jwt", "SigningKey", "PrivateKey",
            "ClientSecret", "Database"
        ];

        string[] violations = configurationFiles
            .Where(path => forbiddenKeys.Any(key => File.ReadAllText(path).Contains(key, StringComparison.OrdinalIgnoreCase)))
            .ToArray();

        Assert.Empty(violations);
    }
}
