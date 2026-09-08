# ITI Examination System — Business Rules Agreement

**Status:** Approved business baseline for implementation planning  
**Based on:** `DATABASE_ANALYSIS.md` and `ARCHITECTURE_DESIGN.md`  
**Purpose:** Define the business rules that the new backend must follow before implementation starts.

---

## 1. Scope

This document defines the first approved business rules for the new ITI Examination System backend.

Target stack:

- ASP.NET Core Web API
- Entity Framework Core — Database First
- Clean Architecture
- CQRS
- MediatR
- FluentValidation
- SQL Server

The live database remains the current persistence baseline.

This document does **not** authorize:

- database schema changes;
- migrations;
- deletion or cleanup of legacy data;
- execution of unsafe legacy stored procedures;
- silent repair of historical inconsistencies.

When existing database behavior conflicts with this document, the new API must follow these rules for **new write operations**.

Legacy inconsistent records should remain readable and should be identified as legacy/integrity issues rather than silently rewritten.

---

# 2. Student Eligibility and Enrollment

## BR-001 — Student Must Be Enrolled Before Starting an Exam

A student may start an exam only when all of the following are true:

1. The student exists.
2. The exam exists.
3. The exam is `active`.
4. The exam belongs to a course.
5. The student has an active enrollment in that course.
6. The student has not exceeded the allowed attempt count.

For the MVP, the required enrollment state is:

```text
STUDENT_COURSE.status = enrolled
```

The following states do not permit starting a new exam:

```text
completed
withdrawn
failed
```

Same-track membership alone is **not sufficient**.

### Expected flow

```text
StartOrResumeExamAttemptCommand
    |
    +--> Student exists?
    |
    +--> Exam exists?
    |
    +--> Exam active?
    |
    +--> Student enrolled in exam course?
    |
    +--> Attempt allowed?
    |
    +--> Resume current attempt OR create new attempt
```

---

# 3. Exam Attempts

## BR-002 — One Attempt Per Student Per Exam in the MVP

The MVP allows:

```text
MaximumAttempts = 1
```

for each student/exam pair.

The existing `attempt_number` column remains supported by persistence, but retakes are not enabled initially.

### Behavior

If an `in_progress` attempt already exists:

```text
Start again -> Resume the same attempt
```

If a final graded attempt already exists:

```text
Start again -> Reject: attempt limit reached
```

The client must never provide or control `attempt_number`.

The architecture should remain extensible for a future configurable maximum-attempt rule.

---

## BR-003 — Start-or-Resume Must Be Idempotent

Starting the same active exam repeatedly must not create multiple concurrent attempts.

```text
No attempt
   -> create attempt

Existing in-progress attempt
   -> return existing attempt

Existing graded attempt
   -> reject because the MVP attempt limit is reached
```

---

## BR-004 — Student Identity Comes From Authentication

Student-facing attempt operations must derive the student identity from the authenticated user.

The backend must never trust a request-provided student ID as proof of ownership.

Example:

```text
Authenticated student = 120

Attempt.student_id must equal 120
```

Otherwise:

```text
403 Forbidden
```

---

# 4. Exam Timing

## BR-005 — Exam Duration Is Enforced by the Backend

The backend is the source of truth for exam timing.

The deadline is:

```text
deadline = attempt.start_time + exam.duration_minutes
```

The frontend may display a countdown timer, but the frontend clock does not determine validity.

The backend must evaluate the deadline when:

- retrieving an active attempt;
- saving/changing an answer;
- submitting an exam.

Once time expires:

- new answers cannot be saved;
- the attempt must be finalized according to the implementation's timeout handling;
- client clock manipulation must not extend the exam.

Use a backend clock abstraction such as:

```text
IClock
```

to keep time-dependent behavior testable.

---

# 5. Submission Rules

## BR-006 — Incomplete Submission Is Allowed

A student may submit an exam even when some questions are unanswered.

Example:

```text
Questions   = 20
Answered    = 17
Unanswered  = 3
```

Submission is valid.

Each unanswered question receives:

```text
0 marks
```

The frontend should warn the student before final submission, but this warning is a UX concern only.

Example:

```text
You still have 3 unanswered questions.
Submit anyway?
```

---

## BR-007 — Submission Is Final

After successful final submission:

- answers cannot be changed;
- the attempt cannot return to `in_progress`;
- the student cannot submit the same attempt again as a new operation.

A repeated submission request may later be made idempotent, but the first implementation should never create duplicate grading or duplicate attempt results.

---

# 6. Grading Rules

## BR-008 — Supported Question Types

The MVP supports only:

```text
MCQ
TrueFalse
```

No manually graded questions are part of the MVP.

---

## BR-009 — Objective Grading Is Full-or-Zero

For each exam question:

```text
Correct answer -> full EXAM_QUES.marks_allocated
Wrong answer   -> 0
Unanswered     -> 0
```

Partial credit is not supported.

The existing historical data that suggests fractional marks is treated as legacy inconsistency and must not define new behavior.

---

## BR-010 — Grading Values Are Server-Controlled

The API client must never submit trusted values for:

```text
is_correct
marks_earned
total_score
attempt_status
passing_result
```

The client sends only the selected answer identity.

Example request concept:

```json
{
  "examQuestionId": "EX001-Q001",
  "selectedChoiceId": "C123"
}
```

The backend determines:

- whether the placement belongs to the attempt's exam;
- whether the choice belongs to the question;
- whether the selected choice is correct;
- marks earned;
- total score;
- pass/fail.

---

## BR-011 — Exam-Specific Marks Are Authoritative

Marks awarded for a correct answer come from:

```text
EXAM_QUES.marks_allocated
```

not directly from:

```text
QUESTION.marks
```

`QUESTION.marks` may remain a default/reference value for question-bank use.

---

# 7. Question Bank Rules

## BR-012 — Every Objective Question Must Have a Valid Choice Set

Every objective question used by the new system must have:

```text
At least 2 choices
Exactly 1 correct choice
Unique choice order within the question
```

Invalid legacy questions remain readable for diagnostics but cannot be used in newly activated exams.

---

## BR-013 — MCQ Rules

An MCQ must have:

```text
2 or more choices
Exactly 1 correct choice
```

Example:

```text
What is 2 + 2?

A. 3
B. 4   <- correct
C. 5
D. 6
```

---

## BR-014 — True/False Rules

A `TrueFalse` question must contain exactly two semantic choices:

```text
True
False
```

Therefore:

```text
Choice count     = 2
Correct choices  = 1
```

Arbitrary True/False options are not accepted by the new API.

---

## BR-015 — Question and Choices Are Created Atomically

A question must not be publicly created first and completed later through several unrelated CRUD operations.

Use a business operation such as:

```text
CreateObjectiveQuestionWithChoicesCommand
```

The question and its complete choice set must succeed or fail in one transaction.

---

# 8. Question Editing and Historical Integrity

## BR-016 — Unused Questions Are Editable

A question that has never been added to any exam may be edited normally.

Possible changes include:

- content;
- difficulty;
- default marks;
- choices;
- correct answer.

---

## BR-017 — Questions Used Only in Draft Exams May Be Edited

If a question is used only by draft exams, it may still be changed.

Any affected draft exam must be validated again before activation.

---

## BR-018 — Questions Used in Active or Attempted Exams Are Locked

Once a question is used in an active exam, semantic modifications are prohibited.

Do not allow:

- changing question text;
- changing question type;
- replacing choices;
- changing the correct answer.

If at least one attempt already exists for an exam containing that question, it remains locked for historical integrity.

The current database does not provide question versioning, so the MVP uses immutability instead of silently changing historical exam content.

---

# 9. Instructor Authorization

## BR-019 — Instructor Authoring Requires Course Assignment

For the MVP, an instructor may create or modify questions and exams only for courses to which they are assigned through:

```text
INSTRUCTOR_COURSE
```

### Question authoring

```text
Instructor assigned to course?
    |
   YES -> allowed
    |
    NO -> forbidden
```

### Exam authoring

The same rule applies to:

- creating exams;
- editing draft exams;
- adding/removing exam questions;
- generating random exams;
- activating exams.

`created_by_inst_id` represents authorship and is not sufficient authorization by itself.

---

## BR-020 — Course Instructor May Activate an Exam in the MVP

The MVP does not require a separate approval workflow.

An instructor authorized for the course may activate a valid draft exam.

A future approval role such as track manager or academic manager may be introduced later without changing the core Exam aggregate.

---

# 10. Exam Authoring Rules

## BR-021 — New Exams Start as Draft

Every newly created exam starts with:

```text
status = draft
```

Draft exams cannot be started by students.

---

## BR-022 — Exam Questions Must Belong to the Exam Course

For every placement:

```text
EXAM.course_id == QUESTION.course_id
```

Cross-course exam-question assignments are invalid for all new writes.

Legacy violations remain read-only integrity issues until separate remediation is approved.

---

## BR-023 — Duplicate Questions and Orders Are Forbidden

Within one exam:

```text
Question appears at most once
Question order appears at most once
```

The backend should validate this before persistence and also rely on the existing database uniqueness constraints as the final defense.

---

## BR-024 — Exam Mark Allocation Must Match Before Activation

While editing a draft, a temporary mismatch may exist.

Before activation:

```text
SUM(EXAM_QUES.marks_allocated)
    ==
EXAM.total_marks
```

Activation must fail if the totals do not match.

Also required:

```text
total_marks > 0
passing_score > 0
passing_score <= total_marks
duration_minutes > 0
```

---

## BR-025 — Exam Activation Is the Hard Validation Gate

`ActivateExamCommand` must validate the complete exam definition.

At minimum:

1. Exam exists.
2. Exam status is `draft`.
3. Instructor is authorized.
4. Exam contains at least one question.
5. Every question belongs to the exam's course.
6. Every question has a valid choice set.
7. No duplicate question exists.
8. No duplicate order exists.
9. Allocated marks are positive.
10. Allocated marks sum to `total_marks`.
11. Passing score is valid.
12. Duration is valid.

Validation and status update must happen atomically.

---

# 11. Answering Rules

## BR-026 — Answers May Be Changed While the Attempt Is In Progress

Before final submission and before timeout:

```text
Select A
Change to C
```

is allowed.

There is one current answer for:

```text
Attempt + ExamQuestion
```

Saving another choice replaces the previous current answer.

---

## BR-027 — Answers Cannot Change After Finalization

After the attempt reaches its final state:

```text
graded
```

no student answer may be created, updated, or deleted through the normal student API.

---

## BR-028 — Answer Placement Must Belong to the Attempt's Exam

When saving an answer, the backend must verify:

```text
Attempt.exam_id == ExamQuestion.exam_id
```

and:

```text
SelectedChoice.question_id == ExamQuestion.question_id
```

Both checks are mandatory.

This specifically prevents the cross-exam alignment vulnerability found in the legacy stored procedure behavior.

---

# 12. Submission Transaction

## BR-029 — Submission and Grading Are One Transaction

For the objective-only MVP, final submission performs one atomic workflow:

```text
Validate attempt
    |
Verify ownership
    |
Verify state = in_progress
    |
Apply timing rule
    |
Load exam placements
    |
Validate stored answers
    |
Calculate marks server-side
    |
Calculate total score
    |
Determine pass/fail
    |
Set submit timestamp
    |
Set final status
    |
COMMIT
```

A partially submitted or partially graded attempt must never become externally visible.

---

## BR-030 — Final Attempt State Is Graded

Because all MVP questions are automatically graded, a successfully submitted attempt finishes as:

```text
graded
```

The database value `submitted` does not need to represent a long-running application state in the MVP.

If manually graded question types are introduced later, `submitted` may become a meaningful intermediate state.

---

# 13. Results

## BR-031 — Pass/Fail Uses the Exam Passing Score

After calculating:

```text
total_score
```

the result is:

```text
total_score >= EXAM.passing_score
    -> Pass

total_score < EXAM.passing_score
    -> Fail
```

---

## BR-032 — Legacy Unauditable Results Must Not Be Recalculated Silently

Existing graded attempts with no answer rows cannot be truthfully reconstructed.

The new API must not silently convert them to zero or invent missing answers.

Such results should be represented with an integrity state such as:

```text
Auditable
LegacyUnauditable
IntegrityWarning
```

The exact DTO naming can be decided during implementation.

---

# 14. Course Grade

## BR-033 — Exam Result Does Not Automatically Update Course Grade in the MVP

The current database has two independent concepts:

```text
EXAM_SUBMIT.total_score
STUDENT_COURSE.grade
```

The MVP does not automatically convert exam results into the course letter grade.

Until a grading formula is approved:

```text
SubmitExamAttempt
    -> creates exam result only
```

It must not modify:

```text
STUDENT_COURSE.grade
```

---

# 15. Reporting and Correct Answers

## BR-034 — Active Exam APIs Must Never Expose Correct Answers

Student-facing active exam responses must never include:

```text
CHOICES.is_correct
model answer
correct choice ID
grading metadata
```

---

## BR-035 — Model Answers Are Available Only After Final Submission

For the MVP, students may see model/correct answers only after their own attempt is finalized as:

```text
graded
```

Administrative/instructor reporting may expose correct answers only under the relevant authorization policy.

---

# 16. Legacy Database Policy

## BR-036 — New Writes Must Not Reproduce Known Invalid States

The new API must reject new operations that create known integrity problems, including:

- question without valid choices;
- multiple correct choices;
- cross-course exam question;
- mismatched exam totals at activation;
- cross-exam answer placement;
- client-controlled marks;
- answers after final submission;
- attempts by unenrolled students;
- duplicate concurrent in-progress attempts.

---

## BR-037 — Legacy Invalid Data Remains Readable

Existing inconsistent data is not automatically deleted or repaired.

Queries may return integrity warnings where appropriate.

Cleanup/remediation must be a separate reviewed project.

---

## BR-038 — Unsafe Legacy Write Stored Procedures Are Not Used by New API

The new API must not expose unsafe legacy write behavior such as:

```text
sp_StartExam
sp_SubmitAnswer
sp_SubmitExam
sp_GradeExam
generic CRUD procedures for behavioral aggregates
```

Equivalent use cases should be implemented in the new Application/Domain workflow.

Read-only procedures may be temporarily wrapped only when their output is verified and appropriate authorization is applied.

---

# 17. Database-First and Schema Policy

## BR-039 — Existing Database Is the Persistence Baseline

EF Core should be scaffolded Database First from the live schema.

Do not run automatic migrations.

Do not use:

```text
EnsureCreated
EnsureDeleted
Database.Migrate
```

against the live database.

---

## BR-040 — Non-Domain Tables Are Excluded From Business Features

These tables are not business entities:

```text
STUDENT_TEMP
sysdiagrams
__EFMigrationsHistory
```

They should not receive normal CRUD endpoints or Domain aggregates.

---

# 18. CQRS Rules

## BR-041 — Commands Represent Business Actions

Prefer:

```text
RegisterStudentCommand
EnrollStudentInCourseCommand
CreateObjectiveQuestionWithChoicesCommand
GenerateRandomExamCommand
ActivateExamCommand
StartOrResumeExamAttemptCommand
SaveExamAnswerCommand
SubmitExamAttemptCommand
```

instead of exposing database-table CRUD directly.

---

## BR-042 — Queries Return Purpose-Built Read Models

Queries should return DTOs/projections designed for their consumer.

Examples:

```text
GetAttemptQuestionsQuery
GetAttemptProgressQuery
GetAttemptResultQuery
GetExamDefinitionQuery
ListValidQuestionsForGenerationQuery
```

Queries must not expose:

- tracked EF entities;
- passwords;
- internal grading fields;
- correct choices during an active attempt.

---

# 19. Transaction Boundaries

Explicit transactions are required for:

- question + choices creation/replacement;
- random exam generation;
- exam question reordering;
- exam activation validation + state transition;
- start/resume attempt creation;
- answer upsert with state/alignment recheck;
- final submission + grading;
- any future course-grade calculation involving multiple records.

Simple single-row reference updates may rely on EF Core's normal `SaveChanges` transaction.

---

# 20. MVP Aggregate Boundaries

The richer behavioral aggregates are:

```text
ObjectiveQuestion
    -> Choices

ExamDefinition
    -> ExamQuestions

ExamAttempt
    -> StudentAnswers

CourseEnrollment
```

Other reference/master-data entities should remain pragmatic and should not receive unnecessary ceremonial aggregate abstractions.

---

# 21. Approved MVP Flow

```text
Instructor
    |
    +--> Assigned to Course
    |
    +--> Create Question + Choices
    |
    +--> Create Draft Exam
    |
    +--> Add / Generate Questions
    |
    +--> Validate Exam
    |
    +--> Activate Exam
              |
              v
           Student
              |
              +--> Enrolled in Course?
              |
              +--> Start / Resume Exam
              |
              +--> Answer Questions
              |
              +--> Change Answers while in progress
              |
              +--> Submit incomplete or complete attempt
                         |
                         v
                    Auto Grade
                         |
                 +-------+-------+
                 |               |
                Pass            Fail
                 |               |
                 +-------+-------+
                         |
                         v
                       Result
```

---

# 22. Decisions Deferred Beyond MVP

The following remain intentionally unresolved and must not be guessed during implementation:

1. Multiple attempts / retake policy.
2. Which attempt counts when retakes are enabled.
3. Student-to-intake / track-offering ownership.
4. Re-enrollment in the same course across terms.
5. Question/version snapshots for historical exams.
6. Partial-credit question types.
7. Manually graded questions.
8. Automatic course letter-grade calculation.
9. Separate exam approval workflow.
10. Question retirement/versioning schema.
11. Soft delete and historical audit schema.
12. Repair strategy for the 480 legacy unauditable attempts.
13. Meaning of `EXAM.total_result`.
14. Ownership and deletion policy for `STUDENT_TEMP`.
15. Full retention/deletion policy for historical examination records.

These items require separate business and/or database design approval.

---

# 23. Implementation Source-of-Truth Order

For the new backend, use the following order when deciding behavior:

```text
1. BUSINESS_RULES.md
2. Approved architecture decisions
3. ARCHITECTURE_DESIGN.md
4. DATABASE_ANALYSIS.md
5. Live database schema for persistence compatibility
6. Existing stored procedures / legacy code
7. Old documentation / ERD / report snapshots
```

The live database remains the source of truth for its **actual physical schema**, but legacy database behavior must not override an explicitly approved business rule in this document.

---

# 24. Definition of Ready for Implementation

Implementation may begin when a use case:

- is covered by these approved rules;
- does not depend on a deferred business decision;
- has a clear authorization rule;
- has a defined transaction boundary;
- can be implemented without silently changing the live schema.

The recommended first implementation sequence is:

```text
1. Solution skeleton
2. Database-First Infrastructure scaffold
3. Read-only reference queries
4. Students / Profiles / Enrollment
5. Question Bank
6. Exam Authoring
7. Exam Attempts
8. Results
9. Reporting
```

---

**End of approved MVP business rules.**
