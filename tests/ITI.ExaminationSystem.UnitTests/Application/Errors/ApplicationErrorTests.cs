using ITI.ExaminationSystem.Application.Errors;

namespace ITI.ExaminationSystem.UnitTests.Application.Errors;

public sealed class ApplicationErrorTests
{
    [Fact]
    public void Error_kind_catalog_contains_every_approved_semantic_category()
    {
        string[] names = Enum.GetNames<ApplicationErrorKind>();

        Assert.Equal(
            [
                "Validation", "NotFound", "Conflict", "Unauthenticated", "Forbidden",
                "IdentityLinkInvalid", "RoleMismatch", "IntegrityConflict", "Cancellation",
                "UnexpectedInfrastructureFailure"
            ],
            names);
    }

    [Fact]
    public void Error_code_catalog_contains_current_and_reserved_authentication_codes()
    {
        string[] codes =
        [
            ApplicationErrorCodes.ValidationFailed,
            ApplicationErrorCodes.NotFound,
            ApplicationErrorCodes.Conflict,
            ApplicationErrorCodes.Unauthenticated,
            ApplicationErrorCodes.Forbidden,
            ApplicationErrorCodes.IdentityLinkInvalid,
            ApplicationErrorCodes.RoleMismatch,
            ApplicationErrorCodes.IntegrityConflict,
            ApplicationErrorCodes.Cancelled,
            ApplicationErrorCodes.UnexpectedFailure,
            ApplicationErrorCodes.InvalidCredentials,
            ApplicationErrorCodes.AccountLocked,
            ApplicationErrorCodes.InvalidRefreshToken,
            ApplicationErrorCodes.ExpiredRefreshToken,
            ApplicationErrorCodes.RevokedRefreshToken
        ];

        Assert.Equal(15, codes.Distinct(StringComparer.Ordinal).Count());
        Assert.All(codes, code => Assert.False(string.IsNullOrWhiteSpace(code)));
    }

    [Fact]
    public void Validation_error_preserves_deterministic_field_names_and_safe_messages()
    {
        ApplicationError error = ApplicationError.Validation(
            new Dictionary<string, IReadOnlyList<string>>
            {
                ["Name"] = ["Name is required."],
                ["Code"] = ["Code is invalid."]
            });

        Assert.Equal(ApplicationErrorKind.Validation, error.Kind);
        Assert.Equal(ApplicationErrorCodes.ValidationFailed, error.Code);
        Assert.Equal("Validation failed.", error.Message);
        Assert.Equal(["Code", "Name"], error.FieldErrors.Keys);
    }
}
