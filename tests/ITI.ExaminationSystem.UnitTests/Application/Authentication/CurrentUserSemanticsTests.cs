using ITI.ExaminationSystem.Application.Abstractions.Authentication;

namespace ITI.ExaminationSystem.UnitTests.Application.Authentication;

public sealed class CurrentUserSemanticsTests
{
    [Fact]
    public void Anonymous_actor_exposes_no_identity_role_or_domain_link()
    {
        ICurrentUser actor = new TestCurrentUser(false, null, null, null, []);

        Assert.False(actor.IsAuthenticated);
        Assert.Null(actor.UserId);
        Assert.Null(actor.StudentId);
        Assert.Null(actor.InstructorId);
        Assert.Empty(actor.Roles);
    }

    [Fact]
    public void Authenticated_actor_exposes_only_approved_server_established_identity_data()
    {
        ICurrentUser actor = new TestCurrentUser(true, "identity-42", 17, null, ["Student"]);

        Assert.True(actor.IsAuthenticated);
        Assert.Equal("identity-42", actor.UserId);
        Assert.Equal(17, actor.StudentId);
        Assert.Null(actor.InstructorId);
        Assert.Equal(["Student"], actor.Roles);
    }

    private sealed record TestCurrentUser(
        bool IsAuthenticated,
        string? UserId,
        int? StudentId,
        int? InstructorId,
        IReadOnlyCollection<string> Roles) : ICurrentUser;
}
