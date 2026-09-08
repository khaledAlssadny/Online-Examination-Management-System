namespace ITI.ExaminationSystem.UnitTests.Architecture;

public sealed class ProjectReferenceTests
{
    public static TheoryData<string, string[]> ExpectedReferences => new()
    {
        {
            "src/ITI.ExaminationSystem.Domain/ITI.ExaminationSystem.Domain.csproj",
            []
        },
        {
            "src/ITI.ExaminationSystem.Application/ITI.ExaminationSystem.Application.csproj",
            ["src/ITI.ExaminationSystem.Domain/ITI.ExaminationSystem.Domain.csproj"]
        },
        {
            "src/ITI.ExaminationSystem.Infrastructure/ITI.ExaminationSystem.Infrastructure.csproj",
            [
                "src/ITI.ExaminationSystem.Application/ITI.ExaminationSystem.Application.csproj",
                "src/ITI.ExaminationSystem.Domain/ITI.ExaminationSystem.Domain.csproj"
            ]
        },
        {
            "src/ITI.ExaminationSystem.API/ITI.ExaminationSystem.API.csproj",
            [
                "src/ITI.ExaminationSystem.Application/ITI.ExaminationSystem.Application.csproj",
                "src/ITI.ExaminationSystem.Infrastructure/ITI.ExaminationSystem.Infrastructure.csproj"
            ]
        },
        {
            "tests/ITI.ExaminationSystem.UnitTests/ITI.ExaminationSystem.UnitTests.csproj",
            [
                "src/ITI.ExaminationSystem.Application/ITI.ExaminationSystem.Application.csproj",
                "src/ITI.ExaminationSystem.Domain/ITI.ExaminationSystem.Domain.csproj"
            ]
        },
        {
            "tests/ITI.ExaminationSystem.IntegrationTests/ITI.ExaminationSystem.IntegrationTests.csproj",
            [
                "src/ITI.ExaminationSystem.API/ITI.ExaminationSystem.API.csproj",
                "src/ITI.ExaminationSystem.Infrastructure/ITI.ExaminationSystem.Infrastructure.csproj"
            ]
        }
    };

    [Theory]
    [MemberData(nameof(ExpectedReferences))]
    public void Project_has_only_approved_references(string project, string[] expected)
    {
        string projectPath = RepositoryPaths.Project(project);
        IReadOnlySet<string> actual = ArchitectureRules.ProjectReferences(projectPath);
        string[] expectedPaths = expected.Select(RepositoryPaths.Project).ToArray();

        Assert.Empty(ArchitectureRules.UnexpectedReferences(actual, expectedPaths));
        Assert.Empty(ArchitectureRules.UnexpectedReferences(expectedPaths, actual));
    }
}
