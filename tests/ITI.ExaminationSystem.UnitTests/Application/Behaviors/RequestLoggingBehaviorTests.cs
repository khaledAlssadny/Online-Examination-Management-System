using ITI.ExaminationSystem.Application.Abstractions.Diagnostics;
using ITI.ExaminationSystem.Application.Behaviors;
using ITI.ExaminationSystem.Application.Messaging;

namespace ITI.ExaminationSystem.UnitTests.Application.Behaviors;

public sealed class RequestLoggingBehaviorTests
{
    [Fact]
    public async Task Diagnostics_receive_only_allowlisted_operation_outcome_and_duration()
    {
        RecordingDiagnostics diagnostics = new();
        RequestLoggingBehavior<SensitiveCommand, string> behavior = new(diagnostics);
        SensitiveCommand request = new("sentinel-password", "sentinel-token", "correct-answer-sentinel");

        string response = await behavior.Handle(
            request,
            _ => Task.FromResult("handled"),
            CancellationToken.None);

        Assert.Equal("handled", response);
        Assert.Equal(nameof(SensitiveCommand), diagnostics.OperationName);
        Assert.Equal("Succeeded", diagnostics.Outcome);
        Assert.True(diagnostics.ElapsedMilliseconds >= 0);
        Assert.False(request.WasSerialized);
        Assert.DoesNotContain("sentinel", diagnostics.CapturedText, StringComparison.OrdinalIgnoreCase);
    }

    private sealed class SensitiveCommand(string password, string token, string correctAnswer) : ICommand<string>
    {
        public string Password { get; } = password;
        public string Token { get; } = token;
        public string CorrectAnswer { get; } = correctAnswer;
        public bool WasSerialized { get; private set; }

        public override string ToString()
        {
            WasSerialized = true;
            return $"{Password}:{Token}:{CorrectAnswer}";
        }
    }

    private sealed class RecordingDiagnostics : IRequestDiagnostics
    {
        public string OperationName { get; private set; } = string.Empty;
        public string Outcome { get; private set; } = string.Empty;
        public long ElapsedMilliseconds { get; private set; }
        public string CapturedText => $"{OperationName}|{Outcome}|{ElapsedMilliseconds}";

        public void RequestCompleted(string operationName, string outcome, long elapsedMilliseconds)
        {
            OperationName = operationName;
            Outcome = outcome;
            ElapsedMilliseconds = elapsedMilliseconds;
        }
    }
}
