namespace ITI.ExaminationSystem.Application.Abstractions.Authentication;

public interface ICurrentUser
{
    bool IsAuthenticated { get; }

    string? UserId { get; }

    int? StudentId { get; }

    int? InstructorId { get; }

    IReadOnlyCollection<string> Roles { get; }
}
