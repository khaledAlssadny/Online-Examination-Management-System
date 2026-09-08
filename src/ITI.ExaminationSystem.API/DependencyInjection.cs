using ITI.ExaminationSystem.API.Diagnostics;
using ITI.ExaminationSystem.API.Middleware;
using ITI.ExaminationSystem.API.Time;
using ITI.ExaminationSystem.Application;
using ITI.ExaminationSystem.Application.Abstractions.Clock;
using ITI.ExaminationSystem.Application.Abstractions.Diagnostics;
using ITI.ExaminationSystem.Infrastructure;

namespace ITI.ExaminationSystem.API;

internal static class DependencyInjection
{
    public static IServiceCollection AddApiFoundation(this IServiceCollection services)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.AddApplication();
        services.AddProblemDetails();
        services.AddExceptionHandler<GlobalExceptionHandler>();
        services.AddSingleton<IClock, SystemClock>();
        services.AddSingleton<IRequestDiagnostics, RequestDiagnostics>();
        Infrastructure.DependencyInjection.AddInfrastructure();

        return services;
    }
}
