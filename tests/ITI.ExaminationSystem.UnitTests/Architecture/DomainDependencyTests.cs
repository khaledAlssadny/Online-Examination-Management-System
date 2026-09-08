using DomainAssemblyMarker = ITI.ExaminationSystem.Domain.AssemblyMarker;

namespace ITI.ExaminationSystem.UnitTests.Architecture;

public sealed class DomainDependencyTests
{
    [Fact]
    public void Domain_has_no_framework_or_outer_layer_references()
    {
        string[] forbiddenPrefixes =
        [
            "ITI.ExaminationSystem.Application",
            "ITI.ExaminationSystem.Infrastructure",
            "ITI.ExaminationSystem.API",
            "MediatR",
            "FluentValidation",
            "Microsoft.AspNetCore",
            "Microsoft.EntityFrameworkCore",
            "Microsoft.Data.SqlClient",
            "System.Data.SqlClient",
            "Microsoft.Identity"
        ];

        IReadOnlyList<string> violations = ArchitectureRules.ForbiddenAssemblyReferences(
            typeof(DomainAssemblyMarker).Assembly,
            forbiddenPrefixes);

        Assert.Empty(violations);
    }
}
