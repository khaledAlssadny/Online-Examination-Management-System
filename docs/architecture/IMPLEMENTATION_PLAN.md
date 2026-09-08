# ITI Examination System Backend Implementation Plan

Status: implementation roadmap; no production code or database change authorized  
Business authority: [BUSINESS_RULES.md](C:/Users/khale/Downloads/BUSINESS_RULES.md)  
Architecture: [ARCHITECTURE_DESIGN.md](ARCHITECTURE_DESIGN.md)  
Persistence discovery: [DATABASE_ANALYSIS.md](DATABASE_ANALYSIS.md)  
Database baseline: live SQL Server `ITI_EXAMINATION` on `(localdb)\MSSQLLocalDB`

This plan applies the approved MVP rules to the current physical schema. `BUSINESS_RULES.md` controls new business behavior. The live database controls table, column, key, constraint, and stored-procedure compatibility. Existing inconsistent rows remain readable and are never silently repaired.

## 1. Final MVP Scope

The MVP is one ASP.NET Core Web API backed by the existing SQL Server database. It uses Database First EF Core, Clean Architecture, CQRS with MediatR, and FluentValidation.

Included behavior:

- safe read models for organization, assignments, students, enrollments, curriculum, exams, attempts, results, and reports;
- student registration/profile and enrollment operations only where the actor and lifecycle policy are approved before that endpoint is released;
- atomic creation and permitted revision of MCQ and True/False questions with complete choice sets;
- draft exam creation, manual composition, random generation, validation, and activation;
- authenticated start/resume with active course enrollment and one attempt per student/exam;
- timed answer replacement, incomplete final submission, full-or-zero grading, and final `graded` state;
- own-result review after grading, assignment-scoped instructor results, and explicit legacy integrity labels;
- temporary use of verified read-only procedures behind typed interfaces where useful.

Excluded behavior:

- schema changes, migrations, startup schema creation, and legacy data repair;
- generic CRUD for behavioral tables;
- retakes, question snapshots/versioning, partial credit, manually graded questions, exam approval workflow, automatic course grades, and historical deletion/retention workflows;
- business endpoints for `STUDENT_TEMP`, `sysdiagrams`, or `__EFMigrationsHistory`;
- unsafe legacy write procedures.

## 2. Final Feature Boundaries

| Feature | MVP responsibility | Primary tables |
| --- | --- | --- |
| Organization | Read departments, tracks, intakes, and offerings; add narrow writes only when administrative policy is approved. | `DEPARTMENT`, `TRACK`, `INTAKE`, `TRACK_INTAKE` |
| Instructors and Assignments | Read staff/assignments and supply course-assignment authorization. | `INSTRUCTOR`, `INSTRUCTOR_TRACK`, `INSTRUCTOR_COURSE` |
| Students and Profiles | Register accounts and expose privacy-safe self/staff projections; profiles remain separate unless registration policy makes them mandatory. | `STUDENT`, `STUDENT_INFO` |
| Enrollments | Create and read student-course relationships; provide attempt eligibility. | `STUDENT_COURSE` |
| Courses and Curriculum | Read course and ordered topic reference data; narrow curriculum writes may follow approved admin policy. | `COURSE`, `TOPIC` |
| Question Bank | Own complete objective questions and choices, validity, edit locks, and diagnostics. | `QUESTION`, `CHOICES` |
| Exam Authoring | Own draft exam composition, generation, activation, and validation. | `EXAM`, `EXAM_QUES` |
| Exam Attempts | Own start/resume, deadline enforcement, current answers, final submission, and grading. | `EXAM_SUBMIT`, `STUDENT_ANSWER` |
| Results | Project outcome, pass/fail, review visibility, and integrity status. | `EXAM_SUBMIT`, `STUDENT_ANSWER`, exam/question tables |
| Reporting | Produce authorized no-tracking projections and integrity reports. | Relevant operational tables |

Features communicate through narrow Application interfaces. For example, Exam Attempts consumes enrollment eligibility and exam-definition readers; it does not query another feature's `DbSet` directly.

## 3. Final Aggregate Boundaries

### ObjectiveQuestion + Choices

`ObjectiveQuestion` is the root. Public commands never manipulate choices independently. It enforces supported type, complete choice-set validity, one correct choice, unique order, True/False semantics, course assignment authorization, and semantic edit locks. It maps to `QUESTION` and `CHOICES` in one transaction.

### ExamDefinition + ExamQuestions

`ExamDefinition` is the root for `EXAM` and `EXAM_QUES`. Draft composition may be temporarily incomplete. Activation atomically validates the whole definition. Placement marks, course alignment, uniqueness, valid choices, instructor assignment, and draft state are aggregate rules.

### ExamAttempt + StudentAnswers

`ExamAttempt` is the root for `EXAM_SUBMIT` and `STUDENT_ANSWER`. It owns authenticated student identity, attempt limit, idempotent start/resume, deadline, answer upsert, alignment, derived marks, final submission, and result. Its MVP state transition is `in_progress -> graded`.

### CourseEnrollment

`CourseEnrollment` represents `STUDENT_COURSE`. For attempt eligibility it is active only when `status = enrolled`. The existing composite key means a duplicate student/course relationship is rejected; re-enrollment history is deferred. Exam submission never changes its letter grade.

## 4. Approved Commands

| Command | Business use case | MVP status |
| --- | --- | --- |
| `RegisterStudentCommand` | Create an identity-generated student account with a valid track and securely handled credential. | Ready after authentication/credential design is selected. |
| `CreateStudentProfileCommand` | Add the optional one-to-zero-or-one profile for an account. | Ready after field-ownership policy is selected. |
| `UpdateStudentProfileCommand` | Change fields the authenticated student or authorized staff may manage. | Ready after field-ownership policy is selected. |
| `EnrollStudentInCourseCommand` | Create one student-course enrollment used for academic tracking and exam eligibility. | Ready after enrollment actor and cross-track policy are selected. |
| `WithdrawStudentFromCourseCommand` | End an active enrollment without deleting it. | Held until legal transition/date policy is approved. |
| `CompleteCourseEnrollmentCommand` | Mark enrollment completed independently of exam grading. | Held until legal transition/grade policy is approved. |
| `CreateObjectiveQuestionWithChoicesCommand` | Create a valid MCQ or True/False question and all choices atomically. | Approved. |
| `ReviseObjectiveQuestionCommand` | Edit an unused or draft-only question and its permitted fields. | Approved. |
| `ReplaceQuestionChoicesCommand` | Replace the complete choice set atomically when the question is editable. | Approved. |
| `ChangeCorrectChoiceCommand` | Select exactly one correct existing choice when the question is editable. | Approved. |
| `CreateDraftExamCommand` | Create an exam in `draft` for an assigned course. | Approved. |
| `AddQuestionToExamCommand` | Add one valid same-course question with order and allocated marks to an editable draft. | Approved. |
| `RemoveQuestionFromExamCommand` | Remove a placement from an editable draft. | Approved. |
| `ReorderExamQuestionsCommand` | Atomically assign unique question positions in a draft. | Approved. |
| `ChangeExamQuestionMarksCommand` | Change a draft placement's authoritative marks. | Approved. |
| `GenerateRandomExamCommand` | Select a requested mix from the valid same-course pool and persist a draft composition atomically. | Approved; request contract must not invent a deferred difficulty policy. |
| `ActivateExamCommand` | Atomically validate a complete draft and make it startable. | Approved. |
| `StartOrResumeExamAttemptCommand` | Resume the sole in-progress attempt or create attempt 1 for an eligible authenticated student. | Approved. |
| `SaveExamAnswerCommand` | Insert or replace one selected choice before the deadline. | Approved. |
| `SubmitExamAttemptCommand` | Atomically validate, calculate, grade, timestamp, and finalize an incomplete or complete attempt. | Approved. |

No public `CreateExamSubmit`, `UpdateStudentAnswer`, `GradeExam`, or equivalent table command is allowed. Result recalculation, automatic course-grade calculation, question retirement, destructive deletes, and retakes remain outside the MVP.

## 5. Approved Queries

| Feature | Queries |
| --- | --- |
| Organization | `GetDepartmentByIdQuery`, `ListDepartmentsQuery`, `GetTrackByIdQuery`, `ListTracksByDepartmentQuery`, `ListIntakesQuery`, `ListTrackOfferingsQuery` |
| Instructors | `GetInstructorByIdQuery`, `ListInstructorsByTrackQuery`, `GetInstructorAssignmentsQuery`, `GetInstructorWorkloadQuery` |
| Students | `GetStudentSummaryQuery`, `GetStudentProfileQuery`, `GetCurrentStudentProfileQuery`, `ListStudentsByTrackQuery`, `ListStudentsMissingProfilesQuery` |
| Enrollments | `GetCourseEnrollmentQuery`, `ListStudentEnrollmentsQuery`, `ListCourseStudentsQuery`, `CheckExamEligibilityQuery` |
| Courses | `GetCourseByIdQuery`, `ListCoursesByTrackQuery`, `ListCourseTopicsQuery`, `GetCourseDependencySummaryQuery` |
| Question Bank | `GetQuestionByIdQuery`, `SearchQuestionsQuery`, `ListValidQuestionsForGenerationQuery`, `GetQuestionUsageQuery`, `GetQuestionIntegrityQuery` |
| Exam Authoring | `GetExamDefinitionQuery`, `ListExamsByCourseQuery`, `GetExamValidationQuery`, `GetExamBlueprintQuery`, `GetExamUsageQuery` |
| Exam Attempts | `GetActiveAttemptQuery`, `GetAttemptQuestionsQuery`, `GetAttemptProgressQuery`, `ListStudentAttemptsQuery` |
| Results | `GetAttemptResultQuery`, `GetAttemptReviewQuery`, `ListStudentResultsQuery`, `GetExamResultDistributionQuery`, `GetResultAuditStatusQuery` |
| Reporting | `GetStudentsByOrganizationQuery`, `GetStudentAcademicRecordQuery`, `GetInstructorTeachingReportQuery`, `GetCourseTopicsReportQuery`, `GetExamQuestionReportQuery`, `GetStudentExamReviewReportQuery`, `GetIntegrityDashboardQuery` |

All queries return purpose-built, immutable DTOs. They use no tracking and never expose passwords or persistence entities. Active student exam queries omit `CHOICES.is_correct`, correct choice identity, model answers, and grading metadata. Student review includes model answers only after the caller's own attempt is `graded`. Attempt review always selects an explicit attempt.

## 6. Authorization Rules

- Student attempt and result operations derive student ID from the authenticated principal. A mismatched resource returns forbidden.
- Instructor question and exam commands require a matching `INSTRUCTOR_COURSE` row for the resource course. `created_by_inst_id` records authorship and does not grant authority.
- An assigned instructor may activate a valid draft; no separate approval role exists in the MVP.
- Students access only their own profile, enrollments, attempts, and results.
- Instructor result/report access is limited to assigned course scope unless a separately configured administrative policy grants broader access.
- Salary, profile contact data, correct answers, and integrity diagnostics use distinct policies.
- Reports apply row scope and field scope, not endpoint access alone.

The database does not provide an instructor login or role store. ASP.NET Core Identity, JWT access tokens, and rotating refresh tokens are approved; creating the isolated `auth` persistence schema, provisioning accounts, and mapping Identity users to domain IDs remain implementation prerequisites.

## 7. Validation Rules

FluentValidation handles request shape, lengths, ranges, supported enum values, collection completeness, and duplicate values within a request. Handlers/domain models handle existence, current state, authorization, cross-table alignment, usage locks, timing, and aggregate invariants. Live constraints remain the final defense and expected SQL constraint errors map to stable application errors.

Mandatory behavioral checks include:

- validate `STUDENT.track_id` in Application because the live FK is absent;
- require `STUDENT_COURSE.status = enrolled` for a new attempt;
- enforce maximum attempts of one and client-independent attempt number;
- accept only MCQ or True/False, with their approved choice rules;
- prevent semantic question changes after activation or any attempt;
- require same-course exam placement and unique question/order;
- allow draft total mismatch but require exact allocation total at activation;
- accept only selected placement and choice from the answer client;
- verify attempt/exam/placement and choice/question alignment;
- enforce deadline on retrieval, save, and submit;
- give unanswered placements zero and permit incomplete submission;
- calculate correctness, marks, total, and pass/fail on the server;
- distinguish legacy invalid reads from valid new state.

## 8. Transaction Boundaries

Explicit EF Core transactions are required for:

- question plus choices creation or replacement;
- random exam generation;
- exam-question reordering;
- activation validation and state change;
- start/resume lookup, eligibility recheck, and attempt creation;
- answer upsert after ownership, state, deadline, and alignment recheck;
- timeout detection and any resulting finalization;
- final submission, answer validation, marks calculation, total, timestamps, and `graded` transition.

The start transaction must serialize the student/exam decision so concurrent calls cannot create more than one attempt. Saving and submitting must use guarded state checks so an answer cannot race with finalization. Single-row reference writes can use the transaction provided by one `SaveChanges` call. Queries do not call `SaveChanges`.

## 9. Legacy Stored Procedure Decisions

| Procedure/group | Decision | Reason |
| --- | --- | --- |
| `sp_GenerateRandomExam` | Replace with Application logic | Missing approved assignment, choice-validity, course-alignment, and robust key/concurrency enforcement. |
| `sp_ActivateExam` | Replace with Application logic | Does not implement the approved activation gate. |
| `sp_StartExam` | Deprecated/unsafe | Uses track comparison instead of active enrollment, allows max-plus-one races, and lacks approved timing/ownership rules. |
| `sp_SubmitAnswer` | Deprecated/unsafe | Does not verify attempt-to-exam placement alignment or deadline/ownership. |
| `sp_SubmitExam` | Deprecated/unsafe | Submission/grading is not atomic and trusts cached marks; its allowance for incomplete submission does not make it safe. |
| `sp_GradeExam` | Deprecated/unsafe | Can grade invalid state and trusts cached values. |
| `sp_GetExamQuestions` | Keep and wrap temporarily | Student-safe shape is useful only behind ownership, state, and deadline checks; replace with a typed query. |
| `sp_GetStudentProgress` | Keep and wrap temporarily | Read-only; authorization and timing stay in Application. |
| `sp_ViewExamDetails` | Reporting/read-only candidate | Verify result sets and authorization; typed projection is preferred. |
| `sp_ViewSubmissionDetails` | Reporting/read-only candidate | Correct answers require graded-state and scope gates; never call directly from a student endpoint. |
| `sp_GetStudentCoursesAndGrades` | Reporting/read-only candidate | Reports independent enrollment grade; do not reinterpret it as exam result. |
| `sp_GetInstructorCoursesAndStudents` | Reporting/read-only candidate | Label its global course count accurately; it is not section-specific. |
| `sp_GetCourseTopics` | Reporting/read-only candidate | Low-risk ordered read; direct projection is simpler. |
| `sp_GetExamQuestionsAndChoices` | Reporting/read-only candidate | Administrative only because it exposes correctness. |
| `sp_GetStudentsCountByTrackOrDept` | Deprecated/unsafe | Contract is misleading and department filtering is broken. |
| `sp_GetStudentExamAnswersWithModel` | Deprecated/unsafe | Chooses an implicit latest attempt and can misstate legacy results. |
| Generic CRUD procedures | Deprecated for behavioral writes | They bypass aggregate, authorization, timing, and grading rules. |
| Three ID triggers | Keep temporarily | They are physical key-generation infrastructure; verify EF interaction in integration tests. |

Every temporary wrapper stays in Infrastructure behind an Application interface and has integration coverage and a removal issue.

## 10. Database-First EF Core Strategy

- Scaffold only the 18 operational tables into `ITI.ExaminationSystem.Infrastructure/Persistence/DatabaseFirst`.
- Exclude `STUDENT_TEMP`, `sysdiagrams`, and `__EFMigrationsHistory` from business features and the normal `DbContext` surface where scaffold options permit.
- Commit generated entities/configuration and document a repeatable scaffold command so later schema drift is reviewable.
- Do not generate migrations and do not call `EnsureCreated`, `EnsureDeleted`, or `Database.Migrate`.
- Keep generated persistence classes inside Infrastructure. API and Application receive DTOs or rich models.
- Use generated records directly inside Infrastructure for simple reference/master data. Map `QUESTION`/`CHOICES`, `EXAM`/`EXAM_QUES`, `EXAM_SUBMIT`/`STUDENT_ANSWER`, and `STUDENT_COURSE` through aggregate-specific stores.
- Verify identity `STUDENT.stud_id`, string IDs, composite keys, computed columns, cascade/restrict actions, nullable unique profile fields, missing student-track FK, and all three `INSTEAD OF INSERT` triggers.
- Use no generic repository. Add interfaces only for feature use cases, such as `IExamDefinitionStore`, `IExamAttemptStore`, `IEnrollmentEligibilityReader`, and report query services.
- Use a separate disposable/restored integration database. Never point automated tests at live `ITI_EXAMINATION`.

## 11. Project/Solution Creation Plan

When implementation is approved, create:

```text
ITI.ExaminationSystem.sln

src/
  ITI.ExaminationSystem.Domain
  ITI.ExaminationSystem.Application
  ITI.ExaminationSystem.Infrastructure
  ITI.ExaminationSystem.API

tests/
  ITI.ExaminationSystem.UnitTests
  ITI.ExaminationSystem.IntegrationTests
```

Dependency direction is `Domain <- Application`, with Infrastructure implementing Application abstractions and API composing Application plus Infrastructure. Domain has no EF Core, MediatR, FluentValidation, ASP.NET Core, or SQL dependency. API does not expose generated EF types.

Foundation packages are selected and pinned during Phase 0 against the chosen supported .NET version. Package selection must not introduce a second mediator, validation framework, ORM, or repository abstraction.

Infrastructure contains two persistence contexts with different ownership: the Database First `ExaminationDbContext` for existing `dbo` tables and the Identity-owned `AuthDbContext` for future `auth` tables. Only `AuthDbContext` may have migrations, and those migrations require separate approval and may manage only the `auth` schema.

## 12. Infrastructure Scaffold Plan

1. Record the live connection target and a safe scaffold command without storing credentials.
2. Create an isolated integration database from an approved backup/schema baseline.
3. Scaffold the operational tables and inspect generated keys, relationships, nullability, computed values, and column sizes.
4. Remove business exposure for excluded tables without altering the live database.
5. Add `DbContext` registration with migrations and startup schema management disabled.
6. Add transaction, clock, identity, authorization-scope, ID-generation, and constraint-translation adapters.
7. Verify the three ID triggers and EF generated-value behavior before aggregate writes are implemented.
8. Add no-tracking projection services and temporary stored-procedure adapters only where a verified query requires them.
9. Add connection safeguards so test configuration cannot resolve to the live database name/server accidentally.

Authentication infrastructure follows [AUTHENTICATION_AUTHORIZATION_DESIGN.md](AUTHENTICATION_AUTHORIZATION_DESIGN.md): `ApplicationUser` carries nullable direct Student/Instructor links, Identity owns Admin/Instructor/Student roles, JWT tokens contain stable identity claims, and a dedicated `auth.RefreshTokens` table supports hashed rotating refresh credentials.

## 13. Feature-by-Feature Implementation Order

### Phase 0A — Authentication design foundation

- **Build:** solution/projects, references, feature folders, MediatR/FluentValidation pipelines, Problem Details, `IClock`, `ICurrentUser`, focused identity/token contracts, role/link invariants, policy names, and security-safe logging conventions.
- **Layers:** Domain remains auth-free; contracts and auth use cases in Application; HTTP composition placeholders in API.
- **Commands/queries:** authentication command/query contracts and the first reference-query contracts; no persistence implementation.
- **Tables:** none.
- **Rules:** ASP.NET Core Identity is authoritative; roles are Admin/Instructor/Student; role/link combinations are server-controlled; no secret or legacy password exposure.
- **Validation/auth/transaction:** configuration contracts and pure policy checks only; no placeholder authenticated identity in released endpoints.
- **Tests:** architecture dependency tests, role/link invariant tests, error mapping tests, and API smoke test.
- **Dependency:** none.

### Phase 0B — Identity persistence and JWT infrastructure

- **Build:** `ApplicationUser`, Identity services, `AuthDbContext`, explicit `auth` table mappings, hashed rotating refresh-token store, JWT signing/validation, domain-link readers, and isolated migration design.
- **Layers:** Infrastructure implementations and IntegrationTests; API configuration binding.
- **Commands/queries:** internal identity account, token issuance, rotation, revocation, and link-validation operations.
- **Tables:** future `auth.AspNet*`, `auth.RefreshTokens`, and `auth.__EFMigrationsHistory`; existing `dbo.STUDENT`/`dbo.INSTRUCTOR` are read for link validation.
- **Rules:** Student has only StudentId, Instructor has only InstructorId, Admin has neither; one primary role; unique domain link; no legacy credential copy.
- **Validation/auth/transaction:** token configuration validation, Identity password/lockout, atomic refresh rotation and family revocation; no auth migration is generated/applied until separately approved.
- **Tests:** Identity mapping, unique links, password/lockout, JWT validation, refresh concurrency/reuse/revocation, dangling links, and proof that auth migration operations are confined to `auth`.
- **Dependency:** Phase 0A and approval for a non-production auth database before integration completion.

### Phase 0C — Authentication endpoints and RBAC

- **Build:** login, refresh, logout, `/me`, Admin account provisioning, student registration only if approved, JWT bearer setup, role policies, rate limits, and current-user adapter.
- **Layers:** Application auth handlers; Infrastructure Identity/token implementations; API contracts/endpoints/policies.
- **Commands/queries:** `LoginCommand`, `RefreshTokenCommand`, `LogoutCommand`, `GetCurrentUserQuery`, administrative provisioning, and conditional student registration.
- **Tables:** `auth` tables plus linked `STUDENT`/`INSTRUCTOR` reads; student registration may write `STUDENT` only under the final provisioning policy.
- **Rules:** uniform invalid-credential response, lockout, no client-selected role/link, current linked domain row required, 401 versus 403 semantics.
- **Validation/auth/transaction:** request/rate validation; refresh rotates atomically; cross-context registration must be atomic or fail closed.
- **Tests:** login success/failure/lockout, token expiry and refresh reuse, role isolation, invalid links, `/me`, logout, and secret-free logs/errors.
- **Dependency:** Phase 0B and approval to create/use the `auth` schema in the target environment.

### Phase 1 — Database-First Infrastructure

- **Build:** scaffolded context/entities/configurations, connection configuration, mapping verification, safe integration database fixture, constraint translation, transaction implementation.
- **Layers:** Infrastructure and IntegrationTests; API composition registration.
- **Commands/queries:** internal mapping probes only.
- **Tables:** all 18 operational tables; excluded tables receive no business model.
- **Rules:** physical schema is accepted as-is; no migrations or startup schema calls.
- **Validation/auth/transaction:** verify live sizes/check vocabularies; test explicit rollback and generated keys.
- **Tests:** integration tests for every mapping, composite key, identity/computed column, delete action, unique constraint, and ID trigger; configuration test rejects live DB for automated tests.
- **Dependency:** Phase 0A. Phase 0B/0C may proceed alongside domain scaffolding, but protected endpoints cannot ship without 0C.

### Phase 2 — Read-only reference features

- **Build:** purpose-built Organization, assignment, student/profile, enrollment, course/topic, and safe exam reference projections with paging and stable ordering.
- **Layers:** Application queries/DTOs, Infrastructure projections, API endpoints.
- **Queries:** Organization, Instructors, Students, Enrollments, and Courses entries from section 5.
- **Tables:** `DEPARTMENT`, `TRACK`, `INTAKE`, `TRACK_INTAKE`, `INSTRUCTOR`, `INSTRUCTOR_TRACK`, `INSTRUCTOR_COURSE`, `STUDENT`, `STUDENT_INFO`, `STUDENT_COURSE`, `COURSE`, `TOPIC`.
- **Rules:** omit passwords; preserve account-only students with optional profile; do not infer intake ownership; label ambiguous workload semantics.
- **Validation/auth/transaction:** validate IDs, filters, and paging; apply self/staff/field scope; no write transaction.
- **Tests:** query-filter and DTO unit tests; SQL projection integration tests including missing profiles; API tests for scope, privacy, paging, and not-found behavior.
- **Dependency:** Phase 1 and Phase 0C for protected endpoints.

### Phase 3 — Students, Profiles, and Enrollments

- **Build:** approved registration/profile operations, enrollment creation, and reusable eligibility reader. Hold lifecycle commands whose policies remain open.
- **Layers:** Students and Enrollments in Domain/Application; EF stores in Infrastructure; API contracts/endpoints.
- **Commands/queries:** `RegisterStudentCommand`, profile commands, `EnrollStudentInCourseCommand`, enrollment detail/history, `CheckExamEligibilityQuery`.
- **Tables:** `STUDENT`, `STUDENT_INFO`, `STUDENT_COURSE`, with `TRACK` and `COURSE` reads.
- **Rules:** identity-generated student ID; application check for track; unique login/profile values; one student-course row; only `enrolled` grants exam eligibility; exam results do not mutate course grade.
- **Validation/auth/transaction:** credential handling and field ownership follow selected identity policy; registration/profile unit is atomic only if profile is declared mandatory; enrollment insert is atomic and actor-scoped.
- **Tests:** unit tests for eligibility and permitted input; integration tests for identity, unique/null profile behavior, duplicate enrollment, and rollback; API tests for self/staff access and secret suppression.
- **Dependency:** Phases 0A–0C and 1–2, plus profile, enrollment actor, and cross-track decisions.

### Phase 4 — Question Bank

- **Build:** ObjectiveQuestion aggregate, create/revise/replace/change-correct commands, search/usage/validity/diagnostic queries.
- **Layers:** invariant model in Domain; commands, validators, policies, DTOs in Application; aggregate store/projections in Infrastructure; API endpoints.
- **Commands/queries:** Question Bank entries from sections 4 and 5 except retirement.
- **Tables:** `QUESTION`, `CHOICES`, `COURSE`, `INSTRUCTOR_COURSE`, plus `EXAM_QUES`/`EXAM` for usage locks.
- **Rules:** MCQ/TrueFalse only; complete approved choice sets; atomic writes; assigned-course instructor; edits allowed only when unused or draft-only; active/attempted usage locks semantic changes.
- **Validation/auth/transaction:** request collection checks in FluentValidation; course/assignment/usage checks in handler/domain; question plus choices in one transaction.
- **Tests:** unit matrix for choice invariants and edit locks; integration rollback, uniqueness, assignment, and legacy-invalid read tests; API tests for forbidden authors, invalid choices, and correct-answer field scope.
- **Dependency:** Phases 0C and 1–2 with working InstructorId mapping.

### Phase 5 — Exam Authoring

- **Build:** ExamDefinition aggregate, draft commands, manual composition, random generation, activation, and validation/blueprint queries.
- **Layers:** Domain aggregate; Application commands/queries; Infrastructure store/random candidate query; API endpoints.
- **Commands/queries:** Exam Authoring entries from sections 4 and 5, excluding completion/archive until their lifecycle semantics are approved.
- **Tables:** `EXAM`, `EXAM_QUES`, `QUESTION`, `CHOICES`, `COURSE`, `INSTRUCTOR_COURSE`; `EXAM_SUBMIT` for usage checks.
- **Rules:** new status draft; same-course placement; unique question/order; positive authoritative placement marks; draft mismatch allowed; all BR-025 checks at activation; assigned instructor may activate.
- **Validation/auth/transaction:** validate request counts/orders; recheck assignments and candidate validity in transaction; generation, reorder, and activation are explicit atomic units.
- **Tests:** unit activation matrix and selection rules; integration rollback, uniqueness, concurrent activation/edit, insufficient pool, and legacy-invalid exclusion tests; API tests for draft visibility and assignment scope.
- **Dependency:** Phase 4 and Phase 0C resource authorization.

### Phase 6 — Exam Attempts

- **Build:** ExamAttempt aggregate, student-safe question projection, start/resume, answer upsert, progress, deadline handling, and atomic submit/grade.
- **Layers:** Domain lifecycle/grading; Application commands/policies; Infrastructure guarded writes and transactions; API student endpoints.
- **Commands/queries:** `StartOrResumeExamAttemptCommand`, `SaveExamAnswerCommand`, `SubmitExamAttemptCommand`, and Exam Attempts queries.
- **Tables:** `EXAM_SUBMIT`, `STUDENT_ANSWER`, `EXAM`, `EXAM_QUES`, `QUESTION`, `CHOICES`, `STUDENT`, `STUDENT_COURSE`.
- **Rules:** authenticated ownership; active exam; active enrollment; maximum one; idempotent resume; backend deadline; answer alignment; changes before finalization; incomplete submission; full-or-zero placement marks; final graded state.
- **Validation/auth/transaction:** client supplies only placement and choice; use `IClock`; serialize start decision; guarded answer upsert; submit/grading is one transaction; repeated submit cannot regrade.
- **Tests:** unit tests for timing boundaries, ownership, one-attempt decisions, unanswered zero, pass/fail, and state transitions; integration races for start/save/submit, rollback, alignment, and generated IDs; API tests for spoofed IDs, expired attempts, hidden correct answers, and repeated requests.
- **Dependency:** Phases 0C and 3–5 with completed StudentId mapping.

### Phase 7 — Results

- **Build:** result summary/review/history/distribution and integrity-state projections.
- **Layers:** Application DTO/policy, Infrastructure projections, API endpoints.
- **Commands/queries:** no new result command; Results queries from section 5.
- **Tables:** `EXAM_SUBMIT`, `STUDENT_ANSWER`, `EXAM`, `EXAM_QUES`, `QUESTION`, `CHOICES`; `STUDENT_COURSE` only as separately labeled enrollment information.
- **Rules:** pass/fail uses passing score; own graded attempts reveal model answers; active attempts never do; missing legacy answers are unauditable and never recalculated; no course-grade update.
- **Validation/auth/transaction:** explicit attempt ID; student ownership or instructor course scope; reads only.
- **Tests:** integrity-state unit tests; integration cases for auditable and answerless legacy shapes; API tests for pre/post-grade disclosure and cross-student/course access.
- **Dependency:** Phase 6.

### Phase 8 — Reporting

- **Build:** typed administrative/instructor reports, integrity dashboard, and only justified temporary read wrappers.
- **Layers:** Application report contracts/policies, Infrastructure projections/adapters, API endpoints.
- **Commands/queries:** Reporting queries from section 5.
- **Tables:** relevant operational tables; no `STUDENT_TEMP` business report.
- **Rules:** explicit attempt selection, accurate labels, optional profiles, independent enrollment/exam grades, legacy warnings, correct-answer and personal-data scope.
- **Validation/auth/transaction:** validated filters and bounded pages; row/field authorization; read-only, with snapshot transaction only for a report that requires it.
- **Tests:** projection and wrapper integration tests against edge-case fixtures; API access and data-minimization tests; query-plan measurements for representative volumes.
- **Dependency:** Phases 2 and 7.

### Phase 9 — Hardening and legacy retirement

- **Build:** security review, concurrency soak tests, observability, rate/request limits, wrapper removal, performance evidence, and separate remediation/schema proposals.
- **Layers:** cross-cutting API/Application/Infrastructure and test projects.
- **Commands/queries:** no new business use cases without approval.
- **Tables:** no production mutation outside existing feature commands.
- **Rules:** new writes stay valid; legacy rows remain unchanged; sensitive data is absent from responses/logs.
- **Validation/auth/transaction:** verify every endpoint policy and every multi-row rollback; rehearse failure and cancellation behavior.
- **Tests:** full unit/integration/API suite, concurrency and security cases, restore-based deployment smoke test, and regression tests for retired wrappers.
- **Dependency:** all prior phases.

## 14. Testing Plan Per Phase

The phase details above are mandatory. Across phases:

- unit tests target domain decisions, validators with meaningful boundaries, authorization policies, and error mapping;
- integration tests run against an isolated SQL Server copy and cover mappings, constraints, transactions, concurrency, triggers, projections, and verified procedure adapters;
- API tests cover authentication, resource authorization, Problem Details, contract binding, privacy, correct-answer disclosure, and attempts to submit derived fields;
- no test runs migrations or destructive setup against live `ITI_EXAMINATION`;
- legacy fixtures include missing profiles, invalid choice sets, cross-course placements, mark mismatches, excessive saved scores, missing enrollments, and graded attempts without answers.

## 15. Definition of Done Per Phase

| Phase | Done when |
| --- | --- |
| 0A | Projects compile, dependencies point inward, auth contracts/policies/errors are defined, and role/link unit tests pass. |
| 0B | Identity/JWT/refresh infrastructure passes isolated persistence and security tests, and reviewed migration output contains only `auth` objects. |
| 0C | Auth endpoints, RBAC, current-user mapping, lockout/rate limits, and provisioning flows pass API tests without exposing secrets. |
| 1 | All selected mappings and triggers are verified against an isolated database; excluded tables have no business surface; schema-management calls are absent. |
| 2 | Reference endpoints return stable, authorized, privacy-safe DTOs and handle known legacy shapes. |
| 3 | Released student/profile/enrollment commands enforce approved policy atomically and eligibility is reusable by attempts. |
| 4 | New objective questions cannot enter an invalid choice state and locked questions reject semantic edits. |
| 5 | Draft composition works, random generation is atomic, and no exam activates unless every approved gate passes. |
| 6 | Concurrent start cannot create a second attempt, timing is server-enforced, answers align, and submit/grade commits once atomically. |
| 7 | Results enforce ownership/disclosure and label legacy unauditable records without recalculation. |
| 8 | Reports have truthful contracts, verified filters/scopes, bounded queries, and no unreviewed procedure dependency. |
| 9 | Security/concurrency/performance evidence is recorded, temporary wrappers have owners/removal status, and no unapproved DB change is bundled. |

Every phase also requires passing relevant unit, integration, and API tests; reviewed documentation; no secrets; and an explicit list of deferred work.

## 16. Remaining Non-Blocking Decisions

These items may be decided without changing the approved core attempt workflow; dependent endpoints remain absent until decided:

- profile mandatory/optional behavior during registration and editable fields;
- student track-change policy;
- cross-track enrollment policy and administrative enrollment transitions;
- exact response for repeated final submission;
- lazy request-time timeout finalization versus an additional background worker for attempts with no later request;
- exact `IntegrityStatus` names;
- controller versus Minimal API endpoint style;
- supported .NET/package versions;
- pagination defaults and report export formats;
- meaning of `INSTRUCTOR_COURSE.course_date` in workload reports;
- availability windows and time-zone conventions beyond elapsed duration.
- student self-registration model: create a new `STUDENT` row or activate a pre-provisioned record;
- login identifier and email-confirmation requirement;
- final password/lockout/token lifetime/clock-skew configuration;
- signing-key algorithm, production key store, and rotation procedure;
- Admin multi-factor requirement and secure bootstrap procedure;
- logout scope: current refresh session or all sessions.

The intentionally deferred business items in `BUSINESS_RULES.md` remain outside the MVP and are not implementation choices.

## 17. Blocking Issues, if any

### Release blockers

1. **Auth schema approval:** Phase 0B/0C integration and deployment require explicit approval to create the isolated `auth` schema/tables and apply `AuthDbContext` migrations. No such change is authorized by this plan.
2. **Provisioning and secrets:** protected endpoints require a secure Admin bootstrap, signing-key storage/rotation, and a selected student activation/provisioning flow.
3. **Phase 3 write policy:** registration/profile/enrollment write endpoints require decisions on profile composition, actor permissions, and cross-track enrollment. Read-only work and later aggregate design can proceed while these endpoints remain disabled.

### Reconciliation findings

No approved rule is technically impossible with the current physical schema. The schema can store a single `in_progress` or `graded` attempt, timestamps, answers, placement marks, and final score. Rules absent from constraints must be enforced by transactions and guarded Application writes.

The following meaningful conflicts remain and are handled explicitly:

| Approved MVP rule | Live database or legacy behavior | Plan response |
| --- | --- | --- |
| Active enrollment is required. | `sp_StartExam` checks track only, and historical attempts often lack matching enrollment. | Replace the procedure; enforce `STUDENT_COURSE.status = enrolled` for new starts; label legacy history. |
| One attempt per student/exam. | The schema and procedure permit increasing `attempt_number`. | Keep physical column/key; enforce maximum one in a serialized start transaction. |
| Backend duration is authoritative. | No constraint or legacy write procedure enforces duration; no expired status exists. | Use `IClock`; finalize to the approved `graded` state through the aggregate transaction. |
| Valid MCQ/TrueFalse choice sets are mandatory. | Live constraints and legacy rows permit invalid sets. | Reject invalid new writes/activation; keep legacy rows diagnostic/read-only. |
| Active/attempted question semantics are immutable. | The schema permits updates and has no versioning. | Run usage checks in guarded question transactions; defer versioning. |
| Instructor course assignment authorizes authoring. | Legacy procedures rely on creator IDs or omit authorization. | Enforce `INSTRUCTOR_COURSE` resource checks in Application. |
| Same-course placements and answer alignment are mandatory. | No composite FK enforces either; legacy procedure has an alignment gap. | Recheck both relationships inside write transactions. |
| Submission and grading are one atomic server calculation. | Legacy submission calls a separate grader and trusts cached answer marks. | Replace all three legacy write procedures with aggregate logic. |
| Correct answers appear only after own graded attempt. | Legacy report procedures can expose them earlier or choose an implicit attempt. | Use explicit-attempt authorized projections; restrict or retire wrappers. |
| Exam result does not update course grade. | Physical stores are already independent; some reports apply their own labels. | Keep them separate and label each result source accurately. |
| Legacy unauditable results remain readable. | 480 discovered graded attempts have no answer rows. | Return integrity status; never silently recalculate or repair. |

The read-only metadata recheck attempted during this reconciliation could not reconnect to LocalDB because the installed SQL client reported an encryption/SSL credential error. No database conclusion in this plan depends on a new query: the required physical facts were already captured from the live database in `DATABASE_ANALYSIS.md`. Connectivity must be revalidated before Phase 1 scaffolding begins.
