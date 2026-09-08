using System.Collections.Frozen;

namespace ITI.ExaminationSystem.Application.Authorization;

public static class ApplicationRoles
{
    public const string Admin = nameof(Admin);
    public const string Instructor = nameof(Instructor);
    public const string Student = nameof(Student);

    public static IReadOnlySet<string> All { get; } =
        new[] { Admin, Instructor, Student }.ToFrozenSet(StringComparer.Ordinal);
}
