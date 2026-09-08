using ApplicationAssemblyMarker = ITI.ExaminationSystem.Application.AssemblyMarker;

namespace ITI.ExaminationSystem.UnitTests.Architecture;

public sealed class ApplicationDependencyTests
{
    [Fact]
    public void Application_does_not_reference_outer_or_forbidden_framework_assemblies()
    {
        string[] forbiddenPrefixes =
        [
            "ITI.ExaminationSystem.Infrastructure",
            "ITI.ExaminationSystem.API",
            "Microsoft.AspNetCore",
            "Microsoft.EntityFrameworkCore",
            "Microsoft.Data.SqlClient",
            "System.Data.SqlClient",
            "Microsoft.IdentityModel",
            "System.IdentityModel.Tokens.Jwt"
        ];

        IReadOnlyList<string> violations = ArchitectureRules.ForbiddenAssemblyReferences(
            typeof(ApplicationAssemblyMarker).Assembly,
            forbiddenPrefixes);

        Assert.Empty(violations);
    }
}
