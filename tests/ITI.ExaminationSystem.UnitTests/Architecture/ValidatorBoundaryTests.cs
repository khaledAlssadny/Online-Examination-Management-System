namespace ITI.ExaminationSystem.UnitTests.Architecture;

public sealed class ValidatorBoundaryTests
{
    [Fact]
    public void Application_validators_do_not_depend_on_database_or_resource_authorization_concerns()
    {
        string applicationRoot = RepositoryPaths.Project("src/ITI.ExaminationSystem.Application");
        string[] validatorFiles = Directory.GetFiles(applicationRoot, "*Validator.cs", SearchOption.AllDirectories);
        string[] forbiddenTerms =
        [
            "DbContext", "EntityFramework", "SqlConnection", "IRepository", "Enrollment",
            "InstructorCourse", "OwnsAttempt", "StateTransition"
        ];

        string[] violations = validatorFiles
            .Where(path => forbiddenTerms.Any(term => File.ReadAllText(path).Contains(term, StringComparison.Ordinal)))
            .ToArray();

        Assert.Empty(violations);
    }
}
