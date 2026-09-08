using ITI.ExaminationSystem.Application.Abstractions.Authentication;
using ITI.ExaminationSystem.Application.Authorization;

namespace ITI.ExaminationSystem.UnitTests.Application.Authentication;

public sealed class ActorIdentityValidatorTests
{
    public static TheoryData<ICurrentUser> ValidActors => new()
    {
        Actor(false, null, null, null),
        Actor(true, "admin-subject", null, null, ApplicationRoles.Admin),
        Actor(true, "instructor-subject", null, 7, ApplicationRoles.Instructor),
        Actor(true, "student-subject", 9, null, ApplicationRoles.Student)
    };

    public static TheoryData<ICurrentUser, string> InvalidActors => new()
    {
        { Actor(true, null, null, null, ApplicationRoles.Admin), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", null, null), ActorIdentityValidator.RoleMismatch },
        { Actor(true, "subject", null, null, ApplicationRoles.Admin, ApplicationRoles.Student), ActorIdentityValidator.RoleMismatch },
        { Actor(true, "subject", null, null, "Unknown"), ActorIdentityValidator.RoleMismatch },
        { Actor(true, "subject", 1, null, ApplicationRoles.Admin), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", null, 1, ApplicationRoles.Admin), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", null, null, ApplicationRoles.Instructor), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", 1, 2, ApplicationRoles.Instructor), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", 1, null, ApplicationRoles.Instructor), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", null, null, ApplicationRoles.Student), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", 1, 2, ApplicationRoles.Student), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(true, "subject", null, 2, ApplicationRoles.Student), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(false, "subject", null, null), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(false, null, null, null, ApplicationRoles.Student), ActorIdentityValidator.IdentityLinkInvalid },
        { Actor(false, null, 1, null), ActorIdentityValidator.IdentityLinkInvalid }
    };

    [Fact]
    public void Primary_role_catalog_contains_exactly_the_three_approved_roles()
    {
        Assert.Equal(3, ApplicationRoles.All.Count);
        Assert.Contains(ApplicationRoles.Admin, ApplicationRoles.All);
        Assert.Contains(ApplicationRoles.Instructor, ApplicationRoles.All);
        Assert.Contains(ApplicationRoles.Student, ApplicationRoles.All);
    }

    [Theory]
    [MemberData(nameof(ValidActors))]
    public void Approved_actor_shapes_are_valid(ICurrentUser actor)
    {
        ActorIdentityValidationResult result = ActorIdentityValidator.Validate(actor);

        Assert.True(result.IsValid);
        Assert.Null(result.ErrorCode);
    }

    [Theory]
    [MemberData(nameof(InvalidActors))]
    public void Invalid_actor_shapes_return_the_approved_error(ICurrentUser actor, string expectedError)
    {
        ActorIdentityValidationResult result = ActorIdentityValidator.Validate(actor);

        Assert.False(result.IsValid);
        Assert.Equal(expectedError, result.ErrorCode);
    }

    private static ICurrentUser Actor(
        bool authenticated,
        string? userId,
        int? studentId,
        int? instructorId,
        params string[] roles) =>
        new TestCurrentUser(authenticated, userId, studentId, instructorId, roles);

    private sealed record TestCurrentUser(
        bool IsAuthenticated,
        string? UserId,
        int? StudentId,
        int? InstructorId,
        IReadOnlyCollection<string> Roles) : ICurrentUser;
}
