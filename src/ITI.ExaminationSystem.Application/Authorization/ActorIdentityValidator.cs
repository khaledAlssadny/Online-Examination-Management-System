using ITI.ExaminationSystem.Application.Abstractions.Authentication;

namespace ITI.ExaminationSystem.Application.Authorization;

public static class ActorIdentityValidator
{
    public const string IdentityLinkInvalid = nameof(IdentityLinkInvalid);
    public const string RoleMismatch = nameof(RoleMismatch);

    public static ActorIdentityValidationResult Validate(ICurrentUser actor)
    {
        ArgumentNullException.ThrowIfNull(actor);

        if (!actor.IsAuthenticated)
        {
            return HasAnonymousShape(actor)
                ? ActorIdentityValidationResult.Valid
                : ActorIdentityValidationResult.Invalid(IdentityLinkInvalid);
        }

        return ValidateAuthenticatedActor(actor);
    }

    private static ActorIdentityValidationResult ValidateAuthenticatedActor(ICurrentUser actor)
    {
        if (string.IsNullOrWhiteSpace(actor.UserId))
            return ActorIdentityValidationResult.Invalid(IdentityLinkInvalid);

        if (actor.Roles.Count != 1)
            return ActorIdentityValidationResult.Invalid(RoleMismatch);

        string role = actor.Roles.Single();
        if (!ApplicationRoles.All.Contains(role))
            return ActorIdentityValidationResult.Invalid(RoleMismatch);

        return HasValidLinks(actor, role)
            ? ActorIdentityValidationResult.Valid
            : ActorIdentityValidationResult.Invalid(IdentityLinkInvalid);
    }

    private static bool HasAnonymousShape(ICurrentUser actor) =>
        actor.UserId is null &&
        actor.StudentId is null &&
        actor.InstructorId is null &&
        actor.Roles.Count == 0;

    private static bool HasValidLinks(ICurrentUser actor, string role) =>
        role switch
        {
            ApplicationRoles.Admin => actor.StudentId is null && actor.InstructorId is null,
            ApplicationRoles.Instructor => actor.StudentId is null && actor.InstructorId is not null,
            ApplicationRoles.Student => actor.StudentId is not null && actor.InstructorId is null,
            _ => false
        };
}

public sealed record ActorIdentityValidationResult
{
    public static ActorIdentityValidationResult Valid { get; } = new(true, null);

    private ActorIdentityValidationResult(bool isValid, string? errorCode)
    {
        IsValid = isValid;
        ErrorCode = errorCode;
    }

    public bool IsValid { get; }

    public string? ErrorCode { get; }

    public static ActorIdentityValidationResult Invalid(string errorCode) => new(false, errorCode);
}
