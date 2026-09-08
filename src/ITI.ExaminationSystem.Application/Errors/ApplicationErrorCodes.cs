namespace ITI.ExaminationSystem.Application.Errors;

public static class ApplicationErrorCodes
{
    public const string ValidationFailed = nameof(ValidationFailed);
    public const string NotFound = nameof(NotFound);
    public const string Conflict = nameof(Conflict);
    public const string Unauthenticated = nameof(Unauthenticated);
    public const string Forbidden = nameof(Forbidden);
    public const string IdentityLinkInvalid = nameof(IdentityLinkInvalid);
    public const string RoleMismatch = nameof(RoleMismatch);
    public const string IntegrityConflict = nameof(IntegrityConflict);
    public const string Cancelled = nameof(Cancelled);
    public const string UnexpectedFailure = nameof(UnexpectedFailure);

    public const string InvalidCredentials = nameof(InvalidCredentials);
    public const string AccountLocked = nameof(AccountLocked);
    public const string InvalidRefreshToken = nameof(InvalidRefreshToken);
    public const string ExpiredRefreshToken = nameof(ExpiredRefreshToken);
    public const string RevokedRefreshToken = nameof(RevokedRefreshToken);
}
