# ITI Examination System Backend Architecture Design

Status: implementation design only  
Authoritative business source: [BUSINESS_RULES.md](C:/Users/khale/Downloads/BUSINESS_RULES.md)  
Authoritative discovery source: [DATABASE_ANALYSIS.md](DATABASE_ANALYSIS.md)  
Database baseline: live SQL Server database `ITI_EXAMINATION` on `(localdb)\MSSQLLocalDB`

This document translates the discovered database into a pragmatic .NET backend design. It defines boundaries, use cases, responsibilities, and migration decisions. It does not authorize schema changes, migrations, production code, or execution of data-changing stored procedures.

## 1. Architecture Overview

The backend should use a modular monolith with Clean Architecture dependency rules and use-case-level CQRS. The system remains one deployable ASP.NET Core Web API and one SQL Server database. Feature folders provide domain separation without introducing distributed-system complexity.

CQRS here means that commands express business actions and queries return purpose-built read models. It does not require separate databases, event sourcing, a repository per table, or generic create/update/delete handlers for every row.

```text
HTTP request
    -> API endpoint/controller
    -> MediatR command or query
    -> Application handler and validation
    -> Domain behavior where the use case has invariants
    -> Infrastructure persistence/query implementation
    -> live SQL Server database
```

The architecture must account for the live database's known integrity gaps:

- application logic cannot rely on `STUDENT.track_id` having a foreign key;
- question choice sets cannot be assumed valid;
- an exam question cannot be assumed to belong to the exam's course;
- exam total marks cannot be assumed to equal allocated question marks;
- a saved attempt score cannot be assumed derivable from saved answers;
- a graded attempt cannot be assumed to have answer rows;
- course enrollment cannot be assumed from an existing attempt;
- current stored procedures cannot be treated as trusted domain services.

New write paths must prevent adding further invalid states. Existing inconsistent records must remain readable and explicitly identified until a separate remediation decision is approved.

## 2. Solution Structure

```text
ITI.ExaminationSystem.sln

src/
  ITI.ExaminationSystem.Domain/
    Common/
    Organization/
    Instructors/
    Students/
    Enrollments/
    Courses/
    QuestionBank/
    ExamAuthoring/
    ExamAttempts/
    Results/

  ITI.ExaminationSystem.Application/
    Abstractions/
      Authentication/
      Authorization/
      Clock/
      Persistence/
      Transactions/
    Behaviors/
    Features/
      Organization/
      InstructorsAndAssignments/
      StudentsAndProfiles/
      Enrollments/
      CoursesAndCurriculum/
      QuestionBank/
      ExamAuthoring/
      ExamAttempts/
      Results/
      Reporting/

  ITI.ExaminationSystem.Infrastructure/
    Authentication/
      Identity/
        ApplicationUser.cs
        AuthDbContext.cs
        Configurations/
        Migrations/        # auth schema only; created only after approval
      Jwt/
      RefreshTokens/
    Persistence/
      DatabaseFirst/
        Entities/
        ExaminationDbContext.cs
        Configurations/
      Commands/
      Queries/
      StoredProcedures/
    Time/

  ITI.ExaminationSystem.API/
    Contracts/
    Endpoints/ or Controllers/
    Authorization/
    Middleware/
    DependencyInjection/

tests/
  ITI.ExaminationSystem.UnitTests/
  ITI.ExaminationSystem.IntegrationTests/
```

The exact endpoint style—controllers or route-grouped Minimal APIs—is an implementation choice. It does not change the Application contracts. Feature folders should align vertically: command, validator, handler, result DTO, and authorization requirement live close together.

The Domain project should stay small. Reference entities with no meaningful behavior do not need ceremonial aggregate abstractions. The four identified behavioral aggregates receive richer models because their invariants span several rows and operations.

## 3. Dependency Rules

```text
Domain <- Application <- API
   ^           ^
   |           |
   +----- Infrastructure
```

- `Domain` depends only on the .NET base class library. It contains business concepts, invariant methods, value objects, enums, and domain errors. It does not reference EF Core, MediatR, FluentValidation, ASP.NET Core, SQL names, or stored procedures.
- `Application` references `Domain`. It owns use-case contracts, MediatR handlers, FluentValidation validators, authorization requirements, DTOs, and persistence abstractions. It defines transaction intent but does not configure SQL Server.
- `Infrastructure` references `Application` and `Domain`. It owns EF Core database-first entities, `DbContext`, mappings, SQL queries, stored-procedure adapters, authentication integrations, and transaction implementations.
- `API` references `Application` and uses Infrastructure only at the composition root for dependency registration. It owns HTTP contracts, authentication/authorization setup, problem responses, versioning, and transport concerns.
- Tests reference the layer under test. Integration tests may reference API and Infrastructure to exercise real mappings against an isolated database copy.

Domain code must not inherit from generated EF types. Application handlers must not expose `DbSet`, `IQueryable`, tracked persistence entities, passwords, or database-generated grading fields to API clients.

## 4. Feature Boundaries

### Organization

**Responsibilities:** manage departments, tracks, intakes, track offerings, and current manager assignments.

**Entities:** `DEPARTMENT`, `TRACK`, `INTAKE`, `TRACK_INTAKE`; `INSTRUCTOR` is referenced for managers.

**Commands:** `CreateDepartment`, `RenameDepartment`, `AssignDepartmentManager`, `CreateTrack`, `RenameTrack`, `AssignTrackManager`, `CreateIntake`, `RescheduleIntake`, `OfferTrackForIntake`, `UpdateTrackOffering`, `CancelTrackOffering`.

**Queries:** department/track lists, department detail, track detail, intakes, track offerings by track or intake, and organization integrity status.

**Rules and validation:** IDs and names are required and length-limited to live column sizes; names must respect live unique constraints; manager IDs must resolve; date ranges and positive capacity follow live checks. Whether a department or intake must have at least one track is a business decision because the database does not enforce it.

**Transaction boundary:** one transaction per command. `CreateTrack` may validate department and manager then insert one row. `OfferTrackForIntake` validates both parents and inserts the association atomically.

**Authorization:** administrators manage structure; department or track managers may receive scoped read access. Whether managers may edit their units is undecided.

**Infrastructure:** database-first entity access and focused existence/read queries. Direct EF persistence is sufficient for these narrow operations.

### Instructors and Assignments

**Responsibilities:** manage instructor records, track staffing, dated course assignments, and manager views.

**Entities:** `INSTRUCTOR`, `INSTRUCTOR_TRACK`, `INSTRUCTOR_COURSE`; reads reference `TRACK`, `COURSE`, and manager columns.

**Commands:** `RegisterInstructor`, `UpdateInstructorDetails`, `AssignInstructorToTrack`, `UpdateInstructorTrackRole`, `RemoveInstructorFromTrack`, `AssignInstructorToCourse`, `RescheduleInstructorCourseAssignment`, `RemoveInstructorCourseAssignment`.

**Queries:** instructor detail, instructors by track, track assignments, course assignments, workload summary, and management responsibilities.

**Rules and validation:** instructor age/gender/salary reflect live checks. Track/course parents must exist. Duplicate composite assignments are rejected. Historical assignment requirements are unresolved because `INSTRUCTOR_TRACK` permits one row per instructor/track and `INSTRUCTOR_COURSE.course_date` is part of the PK.

**Transaction boundary:** one assignment mutation per transaction; a future “replace assignment” command must remove/add atomically only after history semantics are approved.

**Authorization:** administrators manage staff. Instructors view their own assignments. Managers may view members within their scope. Salary access requires a separate privileged policy.

**Infrastructure:** EF for commands; projection queries for workload. Do not use the global course enrollment count as section-specific teaching load.

### Students and Profiles

**Responsibilities:** student account lifecycle, profile data, track association, and self-service profile access.

**Entities:** `STUDENT`, `STUDENT_INFO`; reads reference `TRACK`. `STUDENT_TEMP` is excluded.

**Commands:** `RegisterStudent`, `CreateStudentProfile`, `UpdateStudentProfile`, and conditionally `ChangeStudentTrack` after policy approval. Credential change/reset belongs to the selected authentication design, not generic student CRUD.

**Queries:** student summary without password, student profile, students by track, missing-profile administration list, and current-user profile.

**Rules and validation:** the live student ID is identity-generated. Login uniqueness must be checked and database conflicts translated. Track existence must be checked in application logic because the live FK is absent. Profile is currently optional in live data. Phone/email uniqueness and NULL behavior require validation that matches SQL Server. Passwords must never appear in read DTOs or logs.

**Transaction boundary:** registration may create account and profile in one transaction only if the business decides a profile is mandatory. Otherwise they are separate commands. Credential storage must be atomic with account creation.

**Authorization:** students read/update only their own allowed fields; staff roles read scoped student data; contact and demographic data require narrower access than basic enrollment identity.

**Infrastructure:** EF mapping for `STUDENT` and `STUDENT_INFO`; an authentication abstraction for hashing and verification. Never query or map `STUDENT_TEMP` into the business feature.

### Enrollments

**Responsibilities:** control the lifecycle of a student-course relationship and its course-level result.

**Entities:** `STUDENT_COURSE` with `STUDENT` and `COURSE` references.

**Commands:** `EnrollStudentInCourse`; `WithdrawStudentFromCourse`, `CompleteCourseEnrollment`, and `RecordCourseGrade` remain outside the ready MVP set until their lifecycle, actor, and grade-ownership policies are approved.

**Queries:** enrollment detail, student enrollment history, students in course, active enrollments, and eligibility checks for exam attempts.

**Rules and validation:** prevent duplicate student/course pairs; enforce legal status transitions in application logic; validate dates and grade vocabulary; validate student and course existence. Same-track enrollment is a pending policy. Re-enrollment cannot be represented by the current composite key and must not be simulated silently.

**Transaction boundary:** each lifecycle transition updates one enrollment under a transaction. If an attempt submission later updates a course grade, that cross-feature transaction requires a confirmed grading policy and should be explicit.

**Authorization:** administrators or authorized academic staff enroll/withdraw/complete. Students view their own enrollment. Instructor access depends on course assignment and approved scope.

**Infrastructure:** EF command persistence and optimized read projections. An `IEnrollmentEligibilityReader` can support attempt validation without exposing the enrollment persistence model.

### Courses and Curriculum

**Responsibilities:** course master data, track ownership, optional introducer metadata, and ordered topics.

**Entities:** `COURSE`, `TOPIC`; reads reference `TRACK` and `INSTRUCTOR`.

**Commands:** `CreateCourse`, `UpdateCourseDetails`, `AddCourseTopic`, `UpdateCourseTopic`, `ReorderCourseTopics`, `RemoveCourseTopic`. Course deletion should not be offered initially because live cascade/restrict behavior is complex and historical retention is undecided.

**Queries:** course detail, courses by track/category, ordered topics, and course dependency summary before administrative retirement decisions.

**Rules and validation:** credit hours 1–6, course name uniqueness within track, valid track/introducer, positive unique topic order. A reorder command must update all affected topic orders atomically and avoid transient unique-key collisions.

**Transaction boundary:** single-row course changes use one transaction; topic reordering is one multi-row transaction.

**Authorization:** administrators or curriculum managers write; instructors receive scoped reads. The meaning of `introduce_by` must be decided before it influences authorization.

**Infrastructure:** EF for writes and read projections. Topic ordering may need temporary order values or raw SQL within the same transaction to satisfy the unique constraint safely.

### Question Bank

**Responsibilities:** create and maintain usable objective questions and their complete choice sets.

**Entities:** `QUESTION`, `CHOICES`, referencing `COURSE` and `INSTRUCTOR`.

**Commands:** `CreateObjectiveQuestionWithChoices`, `ReviseObjectiveQuestion`, `ReplaceQuestionChoices`, `ChangeCorrectChoice`, and `RetireQuestion` only after retention semantics are approved.

**Queries:** question detail with choices, questions by course/type/difficulty, valid questions available for generation, usage by exam, and question-integrity diagnostics.

**Rules and validation:** a question must belong to a course and the acting instructor must have an `INSTRUCTOR_COURSE` assignment for that course. Every objective question has at least two choices, unique non-null choice order, and exactly one correct choice. MCQ has two or more choices. True/False has exactly the two semantic choices `True` and `False`, with exactly one correct. Existing invalid rows remain readable for diagnostics but cannot enter newly activated exams. Unused questions and questions used only in draft exams may be edited; a question used by an active exam or any attempted exam is semantically immutable.

**Transaction boundary:** question and choices are created or replaced in one transaction. There must never be an externally visible intermediate state with an incomplete choice set. Do not use the missing live validation triggers as a guarantee.

**Authorization:** instructor writes require a current matching `INSTRUCTOR_COURSE` assignment; authorship alone is insufficient. Correct-choice data is excluded from active student attempt contracts and is available to a student only after that student's attempt is graded.

**Infrastructure:** richer application/domain model mapped to `QUESTION` and `CHOICES`; ID generation for choices must conform to `NVARCHAR(20)` uniqueness. EF handles the unit of work, with explicit loading of choices and usage checks.

### Exam Authoring

**Responsibilities:** draft exam lifecycle, manual composition, random generation, mark allocation, validation, activation, completion, and archive.

**Entities:** `EXAM`, `EXAM_QUES`; reads reference `QUESTION`, `CHOICES`, `COURSE`, and `INSTRUCTOR`.

**Commands:** `CreateDraftExam`, `AddQuestionToExam`, `RemoveQuestionFromExam`, `ReorderExamQuestions`, `ChangeExamQuestionMarks`, `GenerateRandomExam`, and `ActivateExam`. `CompleteExam` and `ArchiveExam` remain outside the ready MVP set until their lifecycle and retention semantics are approved.

**Queries:** exam definition, exams by course/status, draft validation report, available valid questions, exam blueprint, and exam usage summary.

**Rules and validation:** every new exam starts as `draft`. Draft composition may temporarily have a mark-total mismatch. Every placement uses a question from the same course; no duplicate question/order is allowed; allocated marks are positive; and `EXAM_QUES.marks_allocated` is authoritative for grading. Activation is allowed only from `draft` and atomically verifies at least one placement, valid choice sets, same-course questions, unique questions/orders, positive allocations, allocation sum equal to `EXAM.total_marks`, valid passing score and duration, and instructor course assignment. Draft exams cannot be started by students.

**Transaction boundary:** creation plus initial composition is one transaction. Random generation is one transaction. Reordering is one transaction. Activation performs validation and status update in the same transaction so the validated draft cannot change between check and activation.

**Authorization:** an instructor may create, edit, compose, generate, or activate an exam only with a matching `INSTRUCTOR_COURSE` assignment. The MVP has no separate approval role. Students never receive authoring queries.

**Infrastructure:** rich `ExamDefinition` model, EF persistence, an injected random-selection abstraction, and database uniqueness-conflict translation. The legacy random-generation procedure is not trusted for the final implementation.

### Exam Attempts

**Responsibilities:** start or resume a sitting, return student-safe questions, save/change answers, report progress, enforce ownership and timing, and submit once.

**Entities:** `EXAM_SUBMIT`, `STUDENT_ANSWER`; reads reference `EXAM`, `EXAM_QUES`, `QUESTION`, `CHOICES`, `STUDENT`, and potentially `STUDENT_COURSE`.

**Commands:** `StartOrResumeExamAttempt`, `SaveExamAnswer`, and `SubmitExamAttempt`. Timeout finalization is part of the attempt workflow rather than a public administrative command.

**Queries:** active attempt, attempt questions without correct flags, progress, attempt history, and submitted attempt receipt.

**Rules and validation:** derive student identity from authentication. Starting requires an active exam and `STUDENT_COURSE.status = enrolled` for its course. The MVP permits one attempt per student/exam: resume the existing `in_progress` attempt and reject a new start after a graded attempt. Enforce `start_time + duration_minutes` when retrieving, saving, or submitting. Answers may change only while in progress and before the deadline. Verify attempt/exam/placement and choice/question alignment. Incomplete submission is allowed and unanswered placements score zero. Do not accept correctness, marks, total score, status, pass/fail, or attempt number from the client.

**Transaction boundary:** start/resume must serialize attempt-number allocation and in-progress lookup. Saving one answer is an atomic upsert after rechecking attempt state. Submission, grading calculation, timestamp, and final state are one transaction. Concurrency conflicts must prevent answers racing with submission.

**Authorization:** a student can operate only on their own attempt. Staff cannot impersonate a student through the normal endpoint. Administrative interventions require separate audited policies.

**Infrastructure:** rich `ExamAttempt` model, EF transaction and concurrency strategy, server clock, eligibility reader, student-safe question projections, and a database-compatible generated-ID service until keys can be redesigned.

### Results

**Responsibilities:** expose attempt outcomes, pass/fail, answer review when allowed, result audit status, and future course-grade calculation.

**Entities:** `EXAM_SUBMIT`, `STUDENT_ANSWER`, `EXAM`, `EXAM_QUES`, `QUESTION`, `CHOICES`; `STUDENT_COURSE` only after course-grade policy approval.

**Commands:** no routine client command. Candidate administrative commands are `RecalculateAttemptResult` and `RecordCourseGradeFromAssessments`, both blocked until audit and grading policies are decided.

**Queries:** result summary, detailed attempt review, student result history, exam result distribution, and unauditable/inconsistent result diagnostics.

**Rules and validation:** pass/fail is `total_score >= EXAM.passing_score`. New attempts are graded full-or-zero from the current correct choice and `EXAM_QUES.marks_allocated` in the submission transaction; unanswered placements receive zero. Final state is `graded`. Legacy rows with missing answers or contradictory stored values receive an integrity state and are never silently recalculated. Exam results do not update `STUDENT_COURSE.grade` in the MVP.

**Transaction boundary:** new result creation belongs to `SubmitExamAttempt`. Recalculation, if approved, is a separate privileged transaction with an audit record requirement.

**Authorization:** students view only their own results and may see model answers only after their attempt is graded. Instructors require course assignment or another explicitly configured reporting policy; correct-answer reporting is never available through an active-attempt contract.

**Infrastructure:** read projections, integrity-status calculation, and no dependency on `EXAM.total_result` until its meaning is defined.

### Reporting

**Responsibilities:** read-only administrative, instructor, curriculum, enrollment, and result projections.

**Entities:** all domain tables as required; no aggregate owns a report.

**Commands:** none.

**Queries:** students by track/department, student course record, instructor assignments/workload, course topics, exam blueprint, attempt review, result distribution, and integrity dashboards.

**Rules and validation:** validate filter combinations and required scope. Specify whether reports include students without profiles. A query must select an explicit attempt unless “latest attempt” is part of its name and contract.

**Transaction boundary:** read-only, no explicit transaction for ordinary queries. Multi-result consistency can use an explicit read transaction only where the report requires a single snapshot.

**Authorization:** field-level and row-level scope matter. Personal contacts, salary, correct choices, and model answers require separate policies.

**Infrastructure:** no-tracking EF projections or parameterized SQL; legacy reporting procedures may be wrapped temporarily where their result is correct. RDL files remain external report definitions rather than Application dependencies.

## 5. Aggregate Design

### ObjectiveQuestion and Choices

`ObjectiveQuestion` is the behavioral root. Choices cannot be created or corrected independently through public application commands because usability depends on the complete set.

Approved invariant for new writes:

- supported type is MCQ or TrueFalse;
- course and creator are fixed references for authorization and ownership checks;
- content and default marks are valid;
- choice IDs and orders are unique;
- exactly one choice is correct;
- at least two choices exist;
- TrueFalse has exactly two semantic choices, `True` and `False`.

Persistence maps the aggregate to `QUESTION` plus `CHOICES`. Existing invalid questions load into an integrity-aware read model; write commands must reject activation/use or require an explicit repair command. They must not invent missing choices.

### ExamDefinition and ExamQuestions

`ExamDefinition` owns exam lifecycle and placements. A placement references a question-bank item but stores its exam-specific order and marks.

Approved invariant for activation:

- status transition is allowed;
- at least one placement exists;
- every question belongs to the exam course;
- every question is currently valid for use;
- question and order are unique;
- allocated marks sum to `EXAM.total_marks`;
- passing score and duration are valid;
- creator/activator is authorized.

Draft composition commands may temporarily leave totals unmatched while editing. Activation is the hard consistency gate. Questions used by an active exam or any attempted exam are semantically immutable; questions used only by drafts remain editable and force those drafts through activation validation again.

### ExamAttempt and StudentAnswers

`ExamAttempt` is the transactional root for `EXAM_SUBMIT` and `STUDENT_ANSWER`. It owns lifecycle and prevents clients from setting derived values.

Approved MVP state flow:

```text
InProgress -> Graded
```

The live intermediate `submitted` state is written and immediately changed to `graded` by the current procedure. For objective-only synchronous grading, the application can make submission and grading one atomic transition while still persisting the live final value `graded`. If future manual questions are added, `submitted` becomes a meaningful waiting state.

Rules include authenticated ownership, active course enrollment, a one-attempt limit, idempotent start/resume, exam and choice alignment, answer upsert only while in progress and before the deadline, server-calculated full-or-zero marks, incomplete submission, and one final atomic submission. The persistence column still supports an attempt number, but the client cannot set it and retakes remain beyond the MVP.

### CourseEnrollment

`CourseEnrollment` owns the lifecycle stored in `STUDENT_COURSE`.

Potential transitions, subject to approval:

```text
Enrolled -> Completed
    |----> Withdrawn
    +----> Failed
```

It validates dates, grade/status consistency, and authorized actors. The current table cannot represent re-enrollment or multiple terms. The application must reject a second enrollment instead of overwriting history until the persistence model is changed through a separately approved database change.

## 6. Command Catalog

Commands return focused identifiers or outcomes. They never return tracked database entities.

### Organization

| Command | Business use case |
| --- | --- |
| `CreateDepartmentCommand` | Establish a department with its initial manager. |
| `RenameDepartmentCommand` | Change the unique department display name without replacing its identity. |
| `AssignDepartmentManagerCommand` | Transfer current department responsibility to an existing instructor. |
| `CreateTrackCommand` | Establish a track under a department with an initial manager. |
| `RenameTrackCommand` | Change the globally unique track name. |
| `AssignTrackManagerCommand` | Transfer current track responsibility. |
| `CreateIntakeCommand` | Create a valid academic intake date range. |
| `RescheduleIntakeCommand` | Correct intake dates subject to offering-impact checks. |
| `OfferTrackForIntakeCommand` | Associate a track with an intake and set offering dates/capacity. |
| `UpdateTrackOfferingCommand` | Adjust an offering's dates or capacity. |
| `CancelTrackOfferingCommand` | Remove an unused offering after dependency checks. |

### Instructors and Assignments

| Command | Business use case |
| --- | --- |
| `RegisterInstructorCommand` | Add a staff member eligible for assignments and authorship. |
| `UpdateInstructorDetailsCommand` | Change permitted staff details, with salary separately authorized. |
| `AssignInstructorToTrackCommand` | Record that an instructor works in a track. |
| `UpdateInstructorTrackRoleCommand` | Change the free-text role for an existing track assignment. |
| `RemoveInstructorFromTrackCommand` | End/remove current track membership under the approved history policy. |
| `AssignInstructorToCourseCommand` | Record a dated teaching assignment for a course. |
| `RescheduleInstructorCourseAssignmentCommand` | Move the assignment date while preserving composite-key consistency. |
| `RemoveInstructorCourseAssignmentCommand` | Remove an erroneous/current assignment under the approved retention policy. |

### Students and Profiles

| Command | Business use case |
| --- | --- |
| `RegisterStudentCommand` | Create an identity-generated student account with a valid track and securely processed credential. |
| `CreateStudentProfileCommand` | Add the optional dependent profile for an existing account. |
| `UpdateStudentProfileCommand` | Change authorized personal/contact fields without exposing account credentials. |
| `ChangeStudentTrackCommand` | Move a student to another track only if policy and history handling are approved. |

### Enrollments

| Command | Business use case |
| --- | --- |
| `EnrollStudentInCourseCommand` | Create one student-course enrollment after eligibility checks. |
| `WithdrawStudentFromCourseCommand` | Outside the ready MVP set until transition/date policy is approved. |
| `CompleteCourseEnrollmentCommand` | Outside the ready MVP set until completion and grade policy is approved. |
| `RecordCourseGradeCommand` | Outside the ready MVP set; exam submission never performs this operation. |

### Courses and Curriculum

| Command | Business use case |
| --- | --- |
| `CreateCourseCommand` | Add track-owned course master data. |
| `UpdateCourseDetailsCommand` | Correct name, credit hours, category, or introducer without changing identity. |
| `AddCourseTopicCommand` | Add one ordered syllabus item. |
| `UpdateCourseTopicCommand` | Change topic content while preserving order uniqueness. |
| `ReorderCourseTopicsCommand` | Atomically apply a complete or explicit order change. |
| `RemoveCourseTopicCommand` | Remove a syllabus item and resolve ordering under an approved policy. |

### Question Bank

| Command | Business use case |
| --- | --- |
| `CreateObjectiveQuestionWithChoicesCommand` | Create a complete, usable question and its choices atomically. |
| `ReviseObjectiveQuestionCommand` | Change question content, type, marks, or difficulty while respecting exam usage. |
| `ReplaceQuestionChoicesCommand` | Replace the whole choice set atomically so intermediate invalid states are not exposed. |
| `ChangeCorrectChoiceCommand` | Move correctness to exactly one existing choice in one transaction. |
| `RetireQuestionCommand` | Prevent future use while preserving history, only after retirement persistence is decided. |

### Exam Authoring

| Command | Business use case |
| --- | --- |
| `CreateDraftExamCommand` | Create an editable course exam definition with threshold and duration. |
| `AddQuestionToExamCommand` | Add one same-course valid question with order and allocated marks. |
| `RemoveQuestionFromExamCommand` | Remove a placement from an editable draft. |
| `ReorderExamQuestionsCommand` | Atomically change presentation order without duplicate positions. |
| `ChangeExamQuestionMarksCommand` | Change placement marks and report resulting total consistency. |
| `GenerateRandomExamCommand` | Atomically build a draft from a validated eligible pool using requested type counts. |
| `ActivateExamCommand` | Validate the complete definition and make it available for attempts. |
| `CompleteExamCommand` | Outside the ready MVP set until the meaning of definition-level `completed` is approved. |
| `ArchiveExamCommand` | Outside the ready MVP set until retention and archive transitions are approved. |

### Exam Attempts and Results

| Command | Business use case |
| --- | --- |
| `StartOrResumeExamAttemptCommand` | Return an existing in-progress attempt or atomically allocate the next allowed attempt for an eligible student. |
| `SaveExamAnswerCommand` | Insert or replace one selected choice for a placement in the caller's active attempt. |
| `SubmitExamAttemptCommand` | Atomically close, calculate, grade, and timestamp an objective attempt. |
| Timeout finalization inside attempt commands | Detect an elapsed deadline and atomically finalize the objective attempt; this is internal workflow behavior, not a public administrative command. |
| `RecalculateAttemptResultCommand` | Outside MVP: privileged repair/regrade requires a separately approved audit and remediation policy. |
| `RecordCourseGradeFromAssessmentsCommand` | Outside MVP: exam submission must not update `STUDENT_COURSE.grade` until a grading formula is approved. |

## 7. Query Catalog

| Feature | Queries |
| --- | --- |
| Organization | `GetDepartmentByIdQuery`, `ListDepartmentsQuery`, `ListTracksByDepartmentQuery`, `GetTrackByIdQuery`, `ListIntakesQuery`, `ListTrackOfferingsQuery` |
| Instructors | `GetInstructorByIdQuery`, `ListInstructorsByTrackQuery`, `GetInstructorAssignmentsQuery`, `GetInstructorWorkloadQuery`, `GetManagementResponsibilitiesQuery` |
| Students | `GetStudentSummaryQuery`, `GetStudentProfileQuery`, `GetCurrentStudentProfileQuery`, `ListStudentsByTrackQuery`, `ListStudentsMissingProfilesQuery` |
| Enrollments | `GetCourseEnrollmentQuery`, `ListStudentEnrollmentsQuery`, `ListCourseStudentsQuery`, `CheckExamEligibilityQuery` |
| Courses | `GetCourseByIdQuery`, `ListCoursesByTrackQuery`, `ListCourseTopicsQuery`, `GetCourseDependencySummaryQuery` |
| Question Bank | `GetQuestionByIdQuery`, `SearchQuestionsQuery`, `ListValidQuestionsForGenerationQuery`, `GetQuestionUsageQuery`, `GetQuestionIntegrityQuery` |
| Exam Authoring | `GetExamDefinitionQuery`, `ListExamsByCourseQuery`, `GetExamValidationQuery`, `GetExamBlueprintQuery`, `GetExamUsageQuery` |
| Exam Attempts | `GetActiveAttemptQuery`, `GetAttemptQuestionsQuery`, `GetAttemptProgressQuery`, `ListStudentAttemptsQuery`, `GetSubmittedAttemptReceiptQuery` |
| Results | `GetAttemptResultQuery`, `GetAttemptReviewQuery`, `ListStudentResultsQuery`, `GetExamResultDistributionQuery`, `GetResultAuditStatusQuery` |
| Reporting | `GetStudentsByOrganizationQuery`, `GetStudentAcademicRecordQuery`, `GetInstructorTeachingReportQuery`, `GetCourseTopicsReportQuery`, `GetExamQuestionReportQuery`, `GetStudentExamReviewReportQuery`, `GetIntegrityDashboardQuery` |

Queries should return immutable DTOs and use no-tracking projections. `GetAttemptQuestionsQuery` must omit correctness. `GetAttemptReviewQuery` must take an explicit attempt ID and apply the model-answer disclosure policy. Paged list queries need stable ordering and bounded page sizes when implemented.

## 8. Validation Strategy

Validation has four layers with different jobs:

1. **HTTP contract validation:** binding, required fields, supported formats, and request size limits in API contracts.
2. **FluentValidation in Application:** field length/range, mutually dependent fields, complete choice collections, unique request-level orders, and syntactic command rules. A MediatR pipeline behavior runs validators before handlers.
3. **Application/domain validation:** database-dependent existence, authorization scope, current state, cross-table alignment, attempt eligibility, aggregate invariants, and transition legality. These checks belong in handlers/domain methods because FluentValidation should not become a persistence orchestration layer.
4. **Database constraints:** final defense against key, FK, unique, and check violations. Infrastructure translates expected SQL errors into stable application conflicts or validation errors.

New-write compatibility rules:

- validate against actual live column sizes and vocabularies;
- explicitly verify `STUDENT.track_id` exists;
- require valid question choice sets for create/repair/use;
- require same-course question placement;
- require attempt/exam/placement alignment;
- require active `STUDENT_COURSE.status = enrolled` when creating an attempt;
- enforce one attempt per student/exam for the MVP and resume the existing in-progress row;
- enforce the server-side deadline on active-attempt retrieval, answer save, and submission;
- calculate correctness and marks server-side;
- calculate total score server-side;
- award zero for unanswered placements and permit incomplete final submission;
- never accept client-provided lifecycle status for behavioral aggregates.

Legacy invalid records should remain queryable with `IntegrityStatus` or warning fields where relevant. A read query should not pretend those rows satisfy new invariants.

## 9. Transaction Strategy

Use one EF Core `DbContext` per request/use case. Commands define transaction boundaries; queries do not call `SaveChanges`.

Explicit transactions are required for:

- ObjectiveQuestion plus all Choices creation/replacement;
- ExamDefinition creation with placements;
- random exam generation;
- exam question reorder;
- activation validation plus status update;
- start/resume attempt and next-attempt allocation;
- answer upsert after state/alignment recheck;
- submission, grading, total calculation, timestamps, and state transition;
- topic reorder;
- any approved cross-feature course-grade update.

Single-row reference updates can rely on one `SaveChanges` transaction. Do not add a generic transaction to every query or handler.

The current schema has no rowversion columns. Until a schema change is approved, concurrency must use guarded SQL updates and uniqueness constraints—for example, update an answer only while its parent attempt remains in progress, and catch duplicate attempt/order keys. Start/resume must prevent `MAX(attempt_number)+1` races through a serializable transaction, appropriate locking, or an equivalent atomic database operation. The exact implementation should be selected and tested in the integration phase.

`StartOrResumeExamAttempt` is idempotent: it returns the existing in-progress attempt and never creates a second one. A repeated submit must never regrade or duplicate results. Whether it returns the existing result or a stable conflict is a transport contract decision that does not change the aggregate invariant.

## 10. Authorization Strategy

ASP.NET Core Identity is the authoritative account/password system. JWT access tokens and rotating refresh tokens authenticate API clients. The legacy `STUDENT.login` and `STUDENT.password` columns are not the new security system; the password is never exposed, logged, claimed, or automatically copied into Identity.

The approved MVP roles are `Admin`, `Instructor`, and `Student`. Use role policies for coarse endpoint access and resource checks in Application or a focused authorization service. The approved capabilities are:

- administrator: organization, staff, and protected repair operations;
- academic manager: scoped department/track/course management where an administrative endpoint is included;
- instructor: authoring only for courses represented by `INSTRUCTOR_COURSE`, plus scoped results;
- student: own profile, enrollment, attempts, and results.

Resource rules:

- a student attempt command derives student identity from the authenticated principal, not request input alone;
- instructor question/exam writes verify the approved course-assignment or management relationship;
- salary, contact data, correct choices, model answers, and integrity repair operations use distinct policies;
- reporting applies row scope as well as endpoint access;
- model answers are never included in active-attempt responses;
- administrative attempt/result changes require auditability, which the current schema does not provide and must be decided before implementation.

`ApplicationUser : IdentityUser<int>` lives in Infrastructure and has nullable `StudentId` and `InstructorId` links. Student accounts require only `StudentId`; Instructor accounts require only `InstructorId`; Admin accounts require neither. Claims carry `sub`, the primary role, and the applicable linked ID. Current course assignments, enrollment, ownership, state, and answer-visibility rules are rechecked from SQL Server because they can change while an access token is valid.

Application owns `ICurrentUser` and focused identity/token use-case contracts. Application handlers do not depend on `HttpContext`, `ClaimsPrincipal`, `UserManager`, or `SignInManager`. The complete design is in [AUTHENTICATION_AUTHORIZATION_DESIGN.md](AUTHENTICATION_AUTHORIZATION_DESIGN.md).

## 11. EF Core Database-First Strategy

Scaffold from the live database into `Infrastructure/Persistence/DatabaseFirst`. Do not generate or apply migrations. Commit generated mappings so schema drift is reviewable, and use a repeatable scaffold command documented during implementation. Since no version is selected yet, package versions and the exact command belong to the implementation phase rather than this design.

### Tables to map

Map the 18 operational domain tables: `INSTRUCTOR`, `INTAKE`, `DEPARTMENT`, `TRACK`, `TRACK_INTAKE`, `INSTRUCTOR_TRACK`, `STUDENT`, `STUDENT_INFO`, `COURSE`, `STUDENT_COURSE`, `INSTRUCTOR_COURSE`, `TOPIC`, `QUESTION`, `CHOICES`, `EXAM`, `EXAM_QUES`, `EXAM_SUBMIT`, and `STUDENT_ANSWER`.

Explicitly exclude from the business model:

- `STUDENT_TEMP`: staging/duplicate table with no dependency and sensitive data;
- `sysdiagrams`: SQL Server tooling;
- `__EFMigrationsHistory`: empty EF bookkeeping, not a domain table.

They may remain physically present. Infrastructure diagnostics can access them through targeted SQL only if a later administrative requirement is approved.

### Persistence entities that can be used directly inside Infrastructure

Generated entities are adequate as persistence records for `DEPARTMENT`, `TRACK`, `INTAKE`, `TRACK_INTAKE`, `INSTRUCTOR`, `INSTRUCTOR_TRACK`, `INSTRUCTOR_COURSE`, `COURSE`, and `TOPIC`. Application DTOs still prevent database shape from leaking across layer boundaries.

`STUDENT` and `STUDENT_INFO` can also use generated persistence records, but authentication and privacy handling require dedicated Application services and DTOs. Password must never be mapped into outward read models.

### Rich models preferred

- `ObjectiveQuestion` over raw `QUESTION` plus `CHOICES` for complete-set validation.
- `ExamDefinition` over raw `EXAM` plus `EXAM_QUES` for composition and lifecycle rules.
- `ExamAttempt` over raw `EXAM_SUBMIT` plus `STUDENT_ANSWER` for ownership, state, timing, and grading.
- `CourseEnrollment` over raw `STUDENT_COURSE` for transition and grade/date consistency.

Mapping between rich models and persistence rows can live in Infrastructure or Application persistence adapters. Avoid a generic repository. Use feature-specific interfaces such as an exam definition store, attempt store, enrollment reader, and report query service only where they express a use-case need.

Preserve live identifiers and relationship configuration. Verify generated mappings for identity `STUDENT.stud_id`, string generated keys, composite keys, `NO ACTION`/cascade deletes, nullable unique columns, computed ages, and absence of the student-track FK. `EnsureCreated`, `EnsureDeleted`, and automatic migration execution must not run in application startup.

Identity uses a separate `AuthDbContext` in Infrastructure, mapped only to the `auth` schema in the same SQL Server database. Its future migrations use a separate migrations assembly/model snapshot and `auth.__EFMigrationsHistory`; generated operations must be reviewed to ensure they create or alter only `auth` objects. `ExaminationDbContext` remains Database First and migration-free. No Identity migration or table is created by this design task.

## 12. Stored Procedure Migration Strategy

Classification applies to the deployed logic described in the discovery document.

| Procedure/group | Classification | Decision and migration path |
| --- | --- | --- |
| `sp_GenerateRandomExam` | Replace with application logic | It omits required instructor assignment, valid-choice and cross-course checks, activation invariants, and robust concurrency/key handling. Reimplement as the atomic `GenerateRandomExamCommand`. |
| `sp_ActivateExam` | Replace with application logic | Current activation checks only existence and one placement. Application activation must validate course alignment, choice validity, totals, status transition, and authorization atomically. |
| `sp_ViewExamDetails` | Reporting/read-only candidate | Its three result sets are useful administratively, but a typed EF projection is easier for API contracts. It may be wrapped temporarily if preserving its shape helps migration. |
| `sp_StartExam` | Deprecated/unsafe | It does not verify actual enrollment, only warns on track mismatch, uses race-prone max-plus-one, and lacks timing/attempt/authorization policy. Do not expose it through the new API. |
| `sp_GetExamQuestions` | Keep and wrap temporarily | It omits correct flags and provides a usable read shape. Wrap only behind attempt ownership/status checks; replace with a typed student-safe query later. |
| `sp_SubmitAnswer` | Deprecated/unsafe | It fails to verify that the placement belongs to the attempt's exam, lacks time/ownership checks, and is not transactionally protected. Replace before enabling new writes. |
| `sp_SubmitExam` | Deprecated/unsafe | Submission and grading are not one explicit transaction, it trusts cached marks, and it does not enforce duration. Its incomplete-submission behavior happens to agree with BR-006, but the unsafe orchestration still requires replacement. |
| `sp_GradeExam` | Deprecated/unsafe | It unconditionally grades any supplied attempt and sums cached marks without state, completeness, alignment, or cap checks. Do not call from the new API. |
| `sp_GetStudentProgress` | Keep and wrap temporarily | Read-only and useful, but authorization and time semantics belong outside it. Replace with typed projection when attempt queries are built. |
| `sp_ViewSubmissionDetails` | Reporting/read-only candidate | Useful result shape, but it can reveal model answers without status/authorization checks and trusts cached grades. Wrap only behind policy or replace with result projection. |
| `sp_GetStudentsCountByTrackOrDept` | Deprecated/unsafe | Name/contract are false: it returns details and ignores department. Replace with explicit track and department queries. |
| `sp_GetStudentCoursesAndGrades` | Reporting/read-only candidate | Correctly reports enrollment data, subject to approved pass/fail policy and student authorization. |
| `sp_GetInstructorCoursesAndStudents` | Reporting/read-only candidate | Can support legacy reports, but its enrollment count is global per course rather than teaching-section-specific. Name DTO fields accordingly. |
| `sp_GetCourseTopics` | Reporting/read-only candidate | Simple ordered read; direct EF projection is preferred, temporary wrapping is low risk. |
| `sp_GetExamQuestionsAndChoices` | Reporting/read-only candidate | Administrative only because it returns correct flags. Protect with authoring/report authorization. |
| `sp_GetStudentExamAnswersWithModel` | Deprecated/unsafe | Silently chooses latest attempt and trusts cached correctness, which produced contradictory report output. Replace with explicit-attempt review query and integrity status. |
| 72 CRUD procedures | Deprecated/unsafe for API writes; selected reads may be temporary | Direct manipulation bypasses aggregate rules, signatures drift from live string/identity keys, update NULL semantics cannot clear values, and select procedures may expose passwords or hide missing profiles. Implement approved use cases instead. |
| Three ID triggers | Keep and wrap temporarily | They are live key-generation infrastructure. New persistence must account for their `INSTEAD OF INSERT` behavior and generated formats until a separately approved key strategy exists. |
| SQL diagram procedures/function | Keep outside application | Tooling objects are unrelated to the backend domain. |

Temporary wrappers must be isolated in Infrastructure behind Application interfaces, covered by integration tests, and marked with a removal target. A wrapper does not make a procedure authoritative; Application still enforces authentication, authorization, parameter validation, and result interpretation.

## 13. Error Handling Strategy

Application errors should be explicit categories:

- validation failure: malformed or internally inconsistent request;
- not found: requested aggregate or reference does not exist;
- conflict: unique collision, illegal state transition, already submitted attempt, or concurrent modification;
- forbidden: authenticated caller lacks resource permission;
- unauthenticated: missing/invalid identity;
- integrity conflict: legacy data prevents a trustworthy operation;
- unexpected infrastructure failure: unavailable database or unclassified SQL error.

The API translates these into a consistent Problem Details response with a stable application error code, trace identifier, safe message, and field errors where applicable. Do not return SQL text, constraint internals, stack traces, passwords, correct choices during attempts, or personal data in logs.

Expected unique/FK/check violations should be mapped by known constraint names. Unknown database exceptions remain server errors and are logged with correlation data. Cancellation must flow through MediatR and EF calls. Logging should record command type, actor ID, resource ID, outcome, and duration without serializing full request objects containing credentials or answers.

## 14. Testing Strategy

### Unit tests

Focus on behavior that does not need SQL Server:

- ObjectiveQuestion complete-choice invariants;
- ExamDefinition activation checks and mark totals;
- ExamAttempt state transitions, answer alignment, grading, unanswered behavior, and timing policy once approved;
- CourseEnrollment transitions and date/grade consistency;
- command validators with boundary values;
- authorization rules expressed as pure policies;
- mapping of domain/application errors to stable results.

Avoid tests that only restate property assignments, MediatR forwarding, or EF behavior.

### Integration tests

Use a disposable/restored test database derived from an approved schema baseline. Never point tests at live `ITI_EXAMINATION`. Do not run migrations against the live database.

Test:

- all database-first mappings, composite keys, identity behavior, computed columns, and delete actions;
- the three `INSTEAD OF INSERT` key triggers and how EF retrieves/uses generated IDs;
- command transaction rollback for question creation, random generation, activation, answer saving, and submission;
- uniqueness/concurrency for attempt start, answer upsert, and question/topic reordering;
- constraint-to-error translation;
- legacy invalid-data read behavior and integrity warnings;
- temporary stored-procedure wrappers, including exact result sets and authorization gates;
- report projections against students without profiles and attempts without answers.

### API tests

Exercise authentication, policy enforcement, Problem Details, input binding, student-safe question output, ownership checks, and prevention of direct derived-field manipulation. Include forbidden and conflict cases, not only successful requests.

## 15. Recommended Implementation Phases

1. **Solution foundation:** create the four source projects and two test projects; enforce dependency direction; add MediatR, FluentValidation, Problem Details, clock, identity, authorization, and transaction abstractions.
2. **Database-first Infrastructure:** scaffold the 18 operational tables, exclude the three non-domain tables, verify mappings and ID triggers, and disable all startup schema management.
3. **Read-only reference features:** implement safe Organization, instructors/assignments, courses/topics, students/profiles, and enrollment projections.
4. **Students, profiles, and enrollments:** implement only approved account/profile/enrollment use cases; keep intake ownership, cross-track policy, re-enrollment, and course-grade derivation outside the MVP.
5. **Question Bank:** implement atomic question/choice creation and permitted revision with assignment authorization and usage locks.
6. **Exam Authoring:** implement draft creation/composition, random generation, validation, and activation under `INSTRUCTOR_COURSE` authorization.
7. **Exam Attempts:** implement authenticated start/resume, student-safe questions, timed answer upsert, progress, and atomic submit/grade with one-attempt policy.
8. **Results:** implement own-result and authorized instructor projections, post-grade model answers, and integrity labeling without legacy recalculation or course-grade mutation.
9. **Reporting:** replace unsafe/incorrect legacy reads with typed projections and wrap only verified read procedures temporarily.
10. **Hardening and legacy retirement:** concurrency, security, observability, performance measurement, wrapper removal, and separate proposals for remediation or schema/index changes.

Each phase should finish with integration tests against the isolated SQL Server database and an updated architecture decision record when a business ambiguity is resolved.

## 16. Business Decisions Still Required

### Resolved by the approved MVP rules

The following former ambiguities are now settled: an active course enrollment is required; same-track membership is insufficient; maximum attempts is one; start/resume is idempotent; identity comes from authentication; duration is enforced by the backend; incomplete submission is allowed; grading is full-or-zero from placement marks; clients cannot supply derived grading fields; MCQ and True/False choice rules are fixed; question/choice writes are atomic; semantic editing locks apply after activation or any attempt; instructor course assignment controls authoring and activation; activation is the hard validation gate; answer changes stop at deadline/finalization; submission and grading are atomic; final state is `graded`; pass/fail uses the exam threshold; legacy unauditable results are labeled rather than recalculated; exam results do not update course grades; and model answers are hidden until the student's attempt is graded.

### Deferred beyond the MVP

These decisions remain intentionally open and their dependent commands or schema behavior stay outside the MVP:

| Decision | Architectural consequence |
| --- | --- |
| Multiple attempts and which attempt counts | Keep `attempt_number` in persistence; enforce one attempt in Application. |
| Student ownership by intake/track offering | Do not infer cohort ownership or enforce offering capacity for students. |
| Re-enrollment across terms | Reject duplicate student/course enrollment; do not overwrite history. |
| Question/version snapshots | Use semantic immutability after activation/attempt; do not invent snapshots. |
| Partial-credit and manually graded types | Support only automatically graded MCQ and True/False. |
| Automatic course letter grades | Keep `EXAM_SUBMIT.total_score` independent of `STUDENT_COURSE.grade`. |
| Separate exam approval | Assigned instructors may activate valid drafts. |
| Question retirement/versioning and soft-delete/audit schema | Omit retirement/delete commands that need new persistence semantics. |
| Legacy attempt repair and full retention/deletion policy | Read and label legacy data; do not repair or delete it. |
| Meaning of `EXAM.total_result` | Exclude it from business calculations. |
| Ownership/deletion of `STUDENT_TEMP` | Exclude it from business features and leave it unchanged. |

### Technical and policy prerequisites

The approved behavior is representable in the current tables, but these implementation choices still need a decision before their affected endpoints can be released:

- student activation/provisioning behavior, Admin bootstrap, production signing-key storage/rotation, and final token/lockout configuration;
- whether a profile is mandatory during registration and which profile fields a student may update;
- whether cross-track course enrollment is allowed for new enrollments;
- legal administrative enrollment transitions and who may record an independent course letter grade;
- availability windows and time-zone conventions beyond the approved duration deadline;
- the HTTP response for repeated submission (return the existing result or a stable conflict); either choice must avoid regrading;
- the exact `IntegrityStatus` DTO vocabulary;
- the meaning of `INSTRUCTOR_COURSE.course_date` for history and workload reports.

Implementation can proceed by phase while endpoints that depend on an unresolved prerequisite remain absent. No approved business rule requires an impossible persistence shape. The current schema lacks constraints for several rules, so Application transactions and guarded writes must enforce them until a separately approved database change is made.
