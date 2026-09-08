using ITI.ExaminationSystem.API;

WebApplicationBuilder builder = WebApplication.CreateBuilder(args);
builder.Services.AddApiFoundation();

WebApplication app = builder.Build();
app.Run();

public partial class Program;
