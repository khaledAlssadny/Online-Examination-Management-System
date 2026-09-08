using System.Xml.Linq;

namespace ITI.ExaminationSystem.UnitTests.Architecture;

public sealed class ForbiddenFoundationTests
{
    private static readonly string[] ForbiddenPackages =
    [
        "ArchUnitNET",
        "EntityFramework",
        "Microsoft.AspNetCore.Authentication.JwtBearer",
        "Microsoft.AspNetCore.Identity",
        "Microsoft.Data.SqlClient",
        "Microsoft.EntityFrameworkCore",
        "NetArchTest",
        "System.Data.SqlClient"
    ];

    [Fact]
    public void Solution_has_no_forbidden_package_reference()
    {
        string[] projectFiles = Directory.GetFiles(RepositoryPaths.Root, "*.csproj", SearchOption.AllDirectories);
        string[] packageNames = projectFiles
            .SelectMany(path => XDocument.Load(path).Descendants("PackageReference"))
            .Select(element => element.Attribute("Include")?.Value ?? string.Empty)
            .ToArray();

        string[] violations = packageNames
            .Where(package => ForbiddenPackages.Any(forbidden =>
                package.Contains(forbidden, StringComparison.OrdinalIgnoreCase)))
            .ToArray();

        Assert.Empty(violations);
        Assert.DoesNotContain(packageNames, package =>
            string.Equals(package, "Mediator", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void Production_source_has_no_generic_repository_or_crud_contract()
    {
        string sourceRoot = RepositoryPaths.Project("src");
        string[] sourceFiles = Directory
            .GetFiles(sourceRoot, "*.cs", SearchOption.AllDirectories)
            .Where(path => !path.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
            .Where(path => !path.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
            .ToArray();
        string[] forbiddenDeclarations =
        [
            "interface IRepository<",
            "class Repository<",
            "interface ICrudService<",
            "class CrudService<"
        ];

        string[] violations = sourceFiles
            .Where(path => forbiddenDeclarations.Any(declaration =>
                File.ReadAllText(path).Contains(declaration, StringComparison.Ordinal)))
            .ToArray();

        Assert.Empty(violations);
    }
}
