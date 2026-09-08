using FluentValidation;
using ITI.ExaminationSystem.Application.Behaviors;
using ITI.ExaminationSystem.Application.Errors;
using ITI.ExaminationSystem.Application.Messaging;

namespace ITI.ExaminationSystem.UnitTests.Application.Behaviors;

public sealed class ValidationBehaviorTests
{
    [Fact]
    public async Task Request_without_validators_reaches_handler_once()
    {
        ValidationBehavior<TestCommand, string> behavior = new([]);
        int handlerCalls = 0;

        string response = await behavior.Handle(
            new TestCommand("valid"),
            _ => { handlerCalls++; return Task.FromResult("handled"); },
            CancellationToken.None);

        Assert.Equal("handled", response);
        Assert.Equal(1, handlerCalls);
    }

    [Fact]
    public async Task All_validators_run_before_a_valid_handler()
    {
        List<string> events = [];
        ValidationBehavior<TestCommand, string> behavior = new(
            [new RecordingValidator("first", events), new RecordingValidator("second", events)]);

        await behavior.Handle(
            new TestCommand("valid"),
            _ => { events.Add("handler"); return Task.FromResult("handled"); },
            CancellationToken.None);

        Assert.Equal(["first", "second", "handler"], events);
    }

    [Fact]
    public async Task Validation_failures_are_sorted_grouped_and_prevent_handler_execution()
    {
        ValidationBehavior<TestCommand, string> behavior = new(
            [new FailureValidator("Name", "Name is required."), new FailureValidator("Code", "Code is invalid."), new FailureValidator("Name", "Name is too short.")]);
        int handlerCalls = 0;

        ApplicationErrorException exception = await Assert.ThrowsAsync<ApplicationErrorException>(() =>
            behavior.Handle(
                new TestCommand("invalid"),
                _ => { handlerCalls++; return Task.FromResult("handled"); },
                CancellationToken.None));

        Assert.Equal(0, handlerCalls);
        Assert.Equal(["Code", "Name"], exception.Error.FieldErrors.Keys);
        Assert.Equal(["Name is required.", "Name is too short."], exception.Error.FieldErrors["Name"]);
    }

    private sealed record TestCommand(string Name) : ICommand<string>;

    private sealed class RecordingValidator(string name, ICollection<string> events) : AbstractValidator<TestCommand>
    {
        public override Task<FluentValidation.Results.ValidationResult> ValidateAsync(
            ValidationContext<TestCommand> context,
            CancellationToken cancellation = default)
        {
            events.Add(name);
            return base.ValidateAsync(context, cancellation);
        }
    }

    private sealed class FailureValidator : AbstractValidator<TestCommand>
    {
        public FailureValidator(string propertyName, string message) =>
            RuleFor(command => command.Name)
                .Must(_ => false)
                .OverridePropertyName(propertyName)
                .WithMessage(message);
    }
}
