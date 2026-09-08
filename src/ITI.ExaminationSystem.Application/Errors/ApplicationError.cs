using System.Collections.ObjectModel;

namespace ITI.ExaminationSystem.Application.Errors;

public sealed record ApplicationError
{
    public ApplicationError(string code, ApplicationErrorKind kind, string message)
        : this(code, kind, message, EmptyFieldErrors)
    {
    }

    public ApplicationError(
        string code,
        ApplicationErrorKind kind,
        string message,
        IReadOnlyDictionary<string, IReadOnlyList<string>> fieldErrors)
    {
        Code = code;
        Kind = kind;
        Message = message;
        FieldErrors = CopyFieldErrors(fieldErrors);
    }

    public string Code { get; }

    public ApplicationErrorKind Kind { get; }

    public string Message { get; }

    public IReadOnlyDictionary<string, IReadOnlyList<string>> FieldErrors { get; }

    public static ApplicationError Validation(IReadOnlyDictionary<string, IReadOnlyList<string>> fieldErrors) =>
        new(ApplicationErrorCodes.ValidationFailed, ApplicationErrorKind.Validation, "Validation failed.", fieldErrors);

    private static IReadOnlyDictionary<string, IReadOnlyList<string>> CopyFieldErrors(
        IReadOnlyDictionary<string, IReadOnlyList<string>> fieldErrors)
    {
        SortedDictionary<string, IReadOnlyList<string>> ordered = new(StringComparer.Ordinal);
        foreach ((string field, IReadOnlyList<string> messages) in fieldErrors)
            ordered[field] = messages.ToArray();

        return new ReadOnlyDictionary<string, IReadOnlyList<string>>(ordered);
    }

    private static IReadOnlyDictionary<string, IReadOnlyList<string>> EmptyFieldErrors { get; } =
        new ReadOnlyDictionary<string, IReadOnlyList<string>>(
            new Dictionary<string, IReadOnlyList<string>>(StringComparer.Ordinal));
}

public sealed class ApplicationErrorException(ApplicationError error) : Exception(error.Message)
{
    public ApplicationError Error { get; } = error;
}
