namespace ITI.ExaminationSystem.UnitTests.Architecture.Fixtures;

public sealed class ForbiddenDependencyFixtures
{
    [Theory]
    [InlineData("Microsoft.AspNetCore.Http", "Microsoft.AspNetCore")]
    [InlineData("Microsoft.EntityFrameworkCore", "Microsoft.EntityFrameworkCore")]
    [InlineData("ITI.ExaminationSystem.Infrastructure", "ITI.ExaminationSystem.Infrastructure")]
    [InlineData("System.IdentityModel.Tokens.Jwt", "System.IdentityModel.Tokens.Jwt")]
    public void Rule_detects_a_deliberately_forbidden_name(string candidate, string prefix)
    {
        IReadOnlyList<string> violations = ArchitectureRules.ForbiddenNames([candidate], prefix);

        Assert.Equal([candidate], violations);
    }

    [Theory]
    [InlineData("Domain", "Application")]
    [InlineData("Domain", "Infrastructure")]
    [InlineData("Domain", "API")]
    [InlineData("Application", "Infrastructure")]
    [InlineData("Application", "API")]
    public void Project_rule_detects_a_deliberately_forbidden_reference(
        string project,
        string forbiddenReference)
    {
        string reference = $"{project}->{forbiddenReference}";

        IReadOnlyList<string> violations = ArchitectureRules.UnexpectedReferences([reference], []);

        Assert.Equal([reference], violations);
    }
}
