namespace ITI.ExaminationSystem.UnitTests.Architecture;

internal static class RepositoryPaths
{
    public static string Root { get; } = FindRoot();

    public static string Project(string relativePath) => Path.GetFullPath(Path.Combine(Root, relativePath));

    private static string FindRoot()
    {
        DirectoryInfo? directory = new(AppContext.BaseDirectory);

        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "ITI.ExaminationSystem.sln")))
            {
                return directory.FullName;
            }

            directory = directory.Parent;
        }

        throw new DirectoryNotFoundException("Could not locate ITI.ExaminationSystem.sln.");
    }
}
