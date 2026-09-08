using ITI.ExaminationSystem.API.Errors;
using ITI.ExaminationSystem.Application.Errors;

namespace ITI.ExaminationSystem.IntegrationTests.API;

public sealed class AuthenticationSemanticsTests
{
    [Fact]
    public void Missing_authentication_and_insufficient_scope_have_distinct_statuses()
    {
        ApplicationError unauthenticated = new(
            ApplicationErrorCodes.Unauthenticated,
            ApplicationErrorKind.Unauthenticated,
            "Authentication is required.");
        ApplicationError forbidden = new(
            ApplicationErrorCodes.Forbidden,
            ApplicationErrorKind.Forbidden,
            "Access is forbidden.");

        Assert.Equal(401, ProblemDetailsMapper.Map(unauthenticated, "trace").Status);
        Assert.Equal(403, ProblemDetailsMapper.Map(forbidden, "trace").Status);
    }
}
