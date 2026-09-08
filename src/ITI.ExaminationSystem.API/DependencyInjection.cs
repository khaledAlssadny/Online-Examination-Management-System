using ITI.ExaminationSystem.API.Time;
using ITI.ExaminationSystem.Application;
using ITI.ExaminationSystem.Application.Abstractions.Clock;
using ITI.ExaminationSystem.Infrastructure;

namespace ITI.ExaminationSystem.API;

internal static class DependencyInjection
{
    public static IServiceCollection AddApiFoundation(this IServiceCollection services)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.AddApplication();
        services.AddSingleton<IClock, SystemClock>();
        Infrastructure.DependencyInjection.AddInfrastructure();

        return services;
    }
}
