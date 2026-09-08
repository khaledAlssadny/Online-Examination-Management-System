using FluentValidation;
using FluentValidation.Results;
using ITI.ExaminationSystem.Application.Errors;
using MediatR;

namespace ITI.ExaminationSystem.Application.Behaviors;

public sealed class ValidationBehavior<TRequest, TResponse>(IEnumerable<IValidator<TRequest>> validators)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        IValidator<TRequest>[] applicableValidators = validators.ToArray();
        if (applicableValidators.Length == 0)
            return await next(cancellationToken);

        IReadOnlyList<ValidationResult> validationResults =
            await ValidateAll(request, applicableValidators, cancellationToken);
        IReadOnlyDictionary<string, IReadOnlyList<string>> fieldErrors = GroupFailures(validationResults);

        return fieldErrors.Count == 0
            ? await next(cancellationToken)
            : throw new ApplicationErrorException(ApplicationError.Validation(fieldErrors));
    }

    private static async Task<IReadOnlyList<ValidationResult>> ValidateAll(
        TRequest request,
        IEnumerable<IValidator<TRequest>> applicableValidators,
        CancellationToken cancellationToken)
    {
        List<ValidationResult> validationResults = [];
        try
        {
            foreach (IValidator<TRequest> validator in applicableValidators)
                validationResults.Add(await validator.ValidateAsync(new ValidationContext<TRequest>(request), cancellationToken));
        }
        catch (OperationCanceledException exception) when (cancellationToken.IsCancellationRequested)
        {
            throw new OperationCanceledException("Request validation was cancelled.", exception, cancellationToken);
        }

        return validationResults;
    }

    private static IReadOnlyDictionary<string, IReadOnlyList<string>> GroupFailures(
        IEnumerable<ValidationResult> validationResults) =>
        validationResults
            .SelectMany(validation => validation.Errors)
            .OrderBy(failure => failure.PropertyName, StringComparer.Ordinal)
            .ThenBy(failure => failure.ErrorMessage, StringComparer.Ordinal)
            .GroupBy(failure => failure.PropertyName, StringComparer.Ordinal)
            .ToDictionary(
                group => group.Key,
                group => (IReadOnlyList<string>)group.Select(failure => failure.ErrorMessage).ToArray(),
                StringComparer.Ordinal);
}
