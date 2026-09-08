using ITI.ExaminationSystem.API;
using ITI.ExaminationSystem.API.Endpoints;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);
builder.Services.AddApiFoundation();

WebApplication app = builder.Build();
app.UseExceptionHandler();
app.MapSystemEndpoints();
app.Run();

public partial class Program;
