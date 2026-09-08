namespace ITI.ExaminationSystem.Application.Authorization;

public static class AuthorizationPolicyNames
{
    public const string StudentOnly = nameof(StudentOnly);
    public const string InstructorOnly = nameof(InstructorOnly);
    public const string AdminOnly = nameof(AdminOnly);
    public const string InstructorAssignedToCourse = nameof(InstructorAssignedToCourse);
    public const string StudentOwnsAttempt = nameof(StudentOwnsAttempt);
    public const string StudentOwnsResult = nameof(StudentOwnsResult);
    public const string CanViewCorrectAnswers = nameof(CanViewCorrectAnswers);
    public const string CanViewSensitiveProfile = nameof(CanViewSensitiveProfile);
    public const string CanViewIntegrityDiagnostics = nameof(CanViewIntegrityDiagnostics);
}
