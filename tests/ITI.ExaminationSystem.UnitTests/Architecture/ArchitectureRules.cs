using System.Reflection;
using System.Xml.Linq;

namespace ITI.ExaminationSystem.UnitTests.Architecture;

internal static class ArchitectureRules
{
    public static IReadOnlySet<string> ProjectReferences(string projectPath)
    {
        XDocument document = XDocument.Load(projectPath);

        return document
            .Descendants("ProjectReference")
            .Select(element => Path.GetFullPath(
                Path.Combine(Path.GetDirectoryName(projectPath)!, element.Attribute("Include")!.Value)))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
    }

    public static IReadOnlyList<string> ForbiddenAssemblyReferences(
        Assembly assembly,
        params string[] forbiddenPrefixes) =>
        ForbiddenNames(
            assembly.GetReferencedAssemblies().Select(reference => reference.Name ?? string.Empty),
            forbiddenPrefixes);

    public static IReadOnlyList<string> ForbiddenNames(
        IEnumerable<string> names,
        params string[] forbiddenPrefixes) =>
        names
            .Where(name => forbiddenPrefixes.Any(prefix =>
                name.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)))
            .Order(StringComparer.OrdinalIgnoreCase)
            .ToArray();

    public static IReadOnlyList<string> UnexpectedReferences(
        IEnumerable<string> actual,
        IEnumerable<string> expected) =>
        actual
            .Except(expected, StringComparer.OrdinalIgnoreCase)
            .Order(StringComparer.OrdinalIgnoreCase)
            .ToArray();
}
