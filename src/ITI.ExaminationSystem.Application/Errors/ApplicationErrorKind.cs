namespace ITI.ExaminationSystem.Application.Errors;

public enum ApplicationErrorKind
{
    Validation,
    NotFound,
    Conflict,
    Unauthenticated,
    Forbidden,
    IdentityLinkInvalid,
    RoleMismatch,
    IntegrityConflict,
    Cancellation,
    UnexpectedInfrastructureFailure
}
