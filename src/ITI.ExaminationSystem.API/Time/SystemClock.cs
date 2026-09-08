using ITI.ExaminationSystem.Application.Abstractions.Clock;

namespace ITI.ExaminationSystem.API.Time;

internal sealed class SystemClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}
