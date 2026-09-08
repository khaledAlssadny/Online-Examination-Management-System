using ITI.ExaminationSystem.Application.Abstractions.Clock;

namespace ITI.ExaminationSystem.UnitTests.Application.Clock;

public sealed class ClockTests
{
    [Fact]
    public void Application_consumer_uses_the_injected_clock_value()
    {
        DateTimeOffset expected = new(2026, 9, 8, 12, 30, 0, TimeSpan.Zero);
        DeadlineEvaluator evaluator = new(new TestClock(expected));

        Assert.True(evaluator.HasReached(expected));
        Assert.False(evaluator.HasReached(expected.AddTicks(1)));
    }

    private sealed class DeadlineEvaluator(IClock clock)
    {
        public bool HasReached(DateTimeOffset deadline) => clock.UtcNow >= deadline;
    }

    private sealed record TestClock(DateTimeOffset UtcNow) : IClock;
}
