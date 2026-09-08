using FluentValidation;
using ITI.ExaminationSystem.Application.Behaviors;
using ITI.ExaminationSystem.Application.Messaging;

namespace ITI.ExaminationSystem.UnitTests.Application.Behaviors;

public sealed class ValidationCancellationTests
{
    [Fact]
    public async Task Cancellation_token_is_forwarded_to_validator_and_handler_is_not_started()
    {
        int handlerCalls = 0;
        CancellationRecordingValidator validator = new();
        ValidationBehavior<TestCommand, string> behavior = new([validator]);
        using CancellationTokenSource source = new();
        source.Cancel();

        OperationCanceledException exception = await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            behavior.Handle(new TestCommand("value"), _ =>
            {
                handlerCalls++;
                return Task.FromResult("handled");
            }, source.Token));

        Assert.Equal(source.Token, validator.ObservedToken);
        Assert.Equal(source.Token, exception.CancellationToken);
        Assert.Equal(0, handlerCalls);
    }

    private sealed record TestCommand(string Name) : ICommand<string>;

    private sealed class CancellationRecordingValidator : AbstractValidator<TestCommand>
    {
        public CancellationToken ObservedToken { get; private set; }

        public override Task<FluentValidation.Results.ValidationResult> ValidateAsync(
            ValidationContext<TestCommand> context,
            CancellationToken cancellation = default)
        {
            ObservedToken = cancellation;
            cancellation.ThrowIfCancellationRequested();
            return base.ValidateAsync(context, cancellation);
        }
    }
}
