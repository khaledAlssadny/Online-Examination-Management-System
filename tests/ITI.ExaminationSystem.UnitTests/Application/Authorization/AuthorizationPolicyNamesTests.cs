using ITI.ExaminationSystem.Application.Authorization;

namespace ITI.ExaminationSystem.UnitTests.Application.Authorization;

public sealed class AuthorizationPolicyNamesTests
{
    [Fact]
    public void Catalog_contains_exactly_the_approved_policy_intent_names()
    {
        string[] policies =
        [
            AuthorizationPolicyNames.StudentOnly,
            AuthorizationPolicyNames.InstructorOnly,
            AuthorizationPolicyNames.AdminOnly,
            AuthorizationPolicyNames.InstructorAssignedToCourse,
            AuthorizationPolicyNames.StudentOwnsAttempt,
            AuthorizationPolicyNames.StudentOwnsResult,
            AuthorizationPolicyNames.CanViewCorrectAnswers,
            AuthorizationPolicyNames.CanViewSensitiveProfile,
            AuthorizationPolicyNames.CanViewIntegrityDiagnostics
        ];

        Assert.Equal(
            [
                "StudentOnly",
                "InstructorOnly",
                "AdminOnly",
                "InstructorAssignedToCourse",
                "StudentOwnsAttempt",
                "StudentOwnsResult",
                "CanViewCorrectAnswers",
                "CanViewSensitiveProfile",
                "CanViewIntegrityDiagnostics"
            ],
            policies);
        Assert.Equal(9, policies.Distinct(StringComparer.Ordinal).Count());
    }
}
