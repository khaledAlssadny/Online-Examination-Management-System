# ITI Examination System Authentication and Authorization Design

Status: approved-direction design; implementation and database changes remain unauthorized  
Business authority: [BUSINESS_RULES.md](C:/Users/khale/Downloads/BUSINESS_RULES.md)  
Architecture: [ARCHITECTURE_DESIGN.md](ARCHITECTURE_DESIGN.md)  
Implementation roadmap: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)  
Persistence discovery: [DATABASE_ANALYSIS.md](DATABASE_ANALYSIS.md)

## 1. Authentication Goals

The authentication system establishes a verified account, issues bounded credentials, and supplies stable actor identity to application use cases. Authorization then combines the account's role with the domain resource being accessed.

ASP.NET Core Identity is the authoritative account, password, lockout, role, and security-stamp system. The legacy `STUDENT.login` and `STUDENT.password` columns are historical application data. Their storage format has not been verified as a secure password hash, so they cannot authenticate the new API.

`STUDENT.password` must never appear in API responses, DTOs, JWT claims, logs, traces, metrics, or exception details. Normal domain queries should project only approved student fields and should avoid loading the password column when possible.

## 2. Identity Architecture

Use a custom integer-key Identity user in Infrastructure:

```text
ApplicationUser : IdentityUser<int>
    StudentId?     -> dbo.STUDENT.stud_id
    InstructorId?  -> dbo.INSTRUCTOR.inst_id
```

For the MVP, `StudentId` and `InstructorId` should be nullable columns directly on `auth.AspNetUsers`. This gives login and token issuance one authoritative account-to-domain link without adding a mapping aggregate or querying claims as stored truth. Add unique filtered indexes so one student or instructor record cannot be linked to multiple active Identity users.

Do not make claims the authoritative mapping. Claims are issued snapshots and can remain valid until token expiry. At sign-in and refresh, load the Identity user links, roles, and referenced domain row. Course assignment and resource ownership are checked against SQL Server during the use case.

To keep Identity migrations isolated, do not add migration-managed foreign keys from `auth.AspNetUsers` to `dbo.STUDENT` or `dbo.INSTRUCTOR` in the MVP. Account provisioning validates the target row transactionally where possible; login/refresh rejects dangling links. A later reviewed schema change may add cross-schema foreign keys after legacy retention/deletion behavior is settled.

Identity types and link fields remain outside Domain entities. Domain models do not inherit from or navigate to `ApplicationUser`.

## 3. Identity Database Strategy

Store Identity in the same `ITI_EXAMINATION` database under a dedicated `auth` schema:

```text
auth.AspNetUsers
auth.AspNetRoles
auth.AspNetUserRoles
auth.AspNetUserClaims
auth.AspNetUserLogins
auth.AspNetRoleClaims
auth.AspNetUserTokens
auth.RefreshTokens
auth.__EFMigrationsHistory
```

The existing examination tables remain in `dbo`. Use two EF Core contexts:

- `ExaminationDbContext`: Database First, maps the existing operational `dbo` tables, has no migrations, and never performs startup schema management.
- `AuthDbContext`: Code First for Identity-owned tables only, derives from the appropriate Identity context, sets default schema `auth`, explicitly maps every Identity table to `auth`, and owns a separate migrations assembly/history table.

Sharing one SQL Server database permits account provisioning and domain-link validation without another service or distributed transaction. Separate contexts preserve ownership: regeneration of `ExaminationDbContext` cannot absorb Identity entities, and an Identity migration model snapshot cannot contain examination tables.

When implementation and database changes are separately approved, generate migrations only with `AuthDbContext`. Review the generated operations and SQL before deployment; they may create or alter only `auth` objects. Apply them through a controlled deployment step. Never call `Database.Migrate`, `EnsureCreated`, or `EnsureDeleted` at API startup. The current task creates no schema, migration, or Identity table.

Microsoft documents Identity model customization and migration-based persistence in [Identity model customization](https://learn.microsoft.com/aspnet/core/security/authentication/customize-identity-model). This project narrows that mechanism to the separate auth-owned context and schema.

## 4. Roles and RBAC

The MVP has exactly three application roles:

| Role | Coarse capability |
| --- | --- |
| `Admin` | User/role provisioning, approved organization and staff administration, protected reporting, and security operations. |
| `Instructor` | Instructor endpoints, assigned-course authoring, and assigned-course results/reporting. |
| `Student` | Own profile, enrollments, exam attempts, and results. |

RBAC controls entry to broad endpoint groups and use-case categories. It does not prove ownership or course scope. AcademicManager, TrackManager, and DepartmentManager may be added later; they do not exist in the MVP policy set.

The MVP should provision exactly one primary role per account. This keeps role/link invariants deterministic. Supporting combined personas requires an explicit later policy.

## 5. Resource-Based Authorization

An `Instructor` role permits instructor use cases, but authoring also requires a current matching `INSTRUCTOR_COURSE` row for the instructor and course. This database check applies to question creation/editing, draft exam creation/editing, placement changes, random generation, activation, and assigned-course result/report access.

`created_by_inst_id` records authorship. It is not authorization. An instructor who authored an item but no longer has the required course assignment cannot modify it through the normal authoring workflow.

A student ID is derived from the authenticated principal. Student endpoints do not accept another student ID as proof of access. If a route contains a student ID for an administrative shape, a normal student request must match the authenticated `StudentId`. Attempt and result handlers load the resource and verify `Attempt.student_id == ICurrentUser.StudentId`; mismatch returns `403 Forbidden`.

Resource checks belong near the use case because they depend on current data. The API performs coarse authenticated/role policy checks; Application authorization requirements or handlers ask focused Infrastructure readers about ownership and assignment. Do not create a generic authorization repository.

## 6. JWT Design

Issue signed short-lived JWT access tokens. Recommended claims:

| Claim | Purpose |
| --- | --- |
| `sub` | Identity user ID; canonical authenticated subject. |
| `jti` | Unique access-token identifier for diagnostics and optional emergency revocation. |
| `iat` | Issued-at time. |
| `role` | One approved MVP role. Multiple role claims remain structurally possible later. |
| `studentId` | Present only for a valid Student account. |
| `instructorId` | Present only for a valid Instructor account. |

`userId` duplicates `sub` and should be omitted. Token validation and current-user parsing treat `sub` as the Identity key.

Do not include passwords, tokens, profile/contact data, correct answers, enrollment state, course assignments, attempt IDs, or other authorization facts that can become stale. Course assignment, enrollment eligibility, attempt ownership, attempt state, and answer visibility are rechecked from SQL Server.

Validate signature, issuer, audience, lifetime, and signing algorithm. Configure a small clock skew. Access tokens are bearer credentials and must be accepted only over HTTPS.

These validation requirements follow Microsoft's [JWT bearer authentication guidance](https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication).

## 7. Access Token and Refresh Token Strategy

Recommended initial configuration is a 10-minute access token and a 14-day absolute refresh-session lifetime, with values held in validated configuration rather than business rules. Security review may adjust them before release.

Use opaque, cryptographically random refresh tokens. Store only a one-way hash in a dedicated `auth.RefreshTokens` table with:

- token record ID and Identity user ID;
- token-family/session ID;
- token hash;
- created, expires, used, and revoked timestamps;
- replacement-token reference;
- revocation reason;
- optional device/session label and audit metadata that does not contain the raw token.

The dedicated table is preferred over `AspNetUserTokens` because rotation, token families, reuse detection, and revocation history need explicit lifecycle columns. It remains owned by `AuthDbContext`, not by the examination domain.

Every successful refresh rotates the token in one transaction: mark the presented token used/revoked, create its replacement, and issue a new access token. Presentation of an expired or revoked token fails. Reuse of an already rotated token revokes the whole token family because it indicates possible theft.

Logout revokes the presented refresh session/family. Password reset, account disablement, role change, or domain-link change revokes all refresh tokens and updates the Identity security stamp. Existing access tokens normally remain usable until their short expiry; high-risk deployments may add a targeted `jti` denylist or per-request security-stamp/version validation after measuring the cost.

## 8. Login Flow

```text
Client
  -> submit login name/email and password
  -> locate Identity account using normalized Identity lookup
  -> verify password and lockout policy through ASP.NET Core Identity
  -> load exactly one primary role
  -> validate role/link combination
  -> verify linked dbo.STUDENT or dbo.INSTRUCTOR row exists
  -> issue JWT access token
  -> create hashed refresh-token record
  -> return token response and safe account summary
```

Failure behavior:

- invalid username or password returns the same `InvalidCredentials` response and must not reveal which value failed;
- locked account returns `AccountLocked` without credential detail;
- missing linked domain row returns `IdentityLinkInvalid`, records a security/administrative event, and issues no token;
- missing or contradictory role/link data returns `RoleMismatch`, records the condition, and issues no token;
- disabled or otherwise disallowed Identity accounts issue no token.

Login success resets failed-access state according to Identity configuration. Refresh repeats role/link/domain-row validation before issuing new credentials.

## 9. Registration / Account Provisioning

Student self-registration is exposed only if the remaining enrollment/account business policy permits it. The workflow creates or selects the domain student record according to that policy, creates the Identity account, links `StudentId`, assigns the Student role, and never copies the legacy password.

Instructor accounts are normally provisioned by an Admin for an existing `INSTRUCTOR` row. Admin accounts are bootstrapped through a controlled deployment/operations process; no public admin registration endpoint exists.

MVP link invariants:

| Primary role | StudentId | InstructorId |
| --- | --- | --- |
| Student | required | null |
| Instructor | null | required |
| Admin | null | null |

Reject missing links, both links set, multiple primary roles, duplicate domain links, nonexistent domain rows, and client-selected roles. Role assignment and link fields are server-controlled.

Cross-context atomicity requires care because Identity and domain records use separate contexts. If public student registration creates both rows, coordinate both contexts over one SQL connection and transaction or use a compensating/provisioning workflow that never exposes a partially active account. The final approach depends on whether registration creates a new `STUDENT` row or links a pre-provisioned one.

## 10. Current User Abstraction

Application defines a small immutable `ICurrentUser` view:

```text
IsAuthenticated
UserId
StudentId?
InstructorId?
Roles
```

Application handlers consume this abstraction and fail closed when required identity data is absent. They do not access `HttpContext`, `ClaimsPrincipal`, `UserManager`, or `SignInManager`.

API authentication middleware validates the JWT. An API adapter parses validated claims into `ICurrentUser`. Claim parsing does not replace database resource checks.

## 11. Identity Service Abstractions

Keep the abstraction set narrow:

- `ICurrentUser` is required for every protected Application use case.
- `IIdentityService` is useful for account creation, role/link changes, password reset, lockout/enable operations, and safe account lookup used by Application commands.
- `ITokenService` is useful for issuing access tokens because signing and JWT libraries belong in Infrastructure.
- `IRefreshTokenService` is useful because rotation, reuse detection, and revocation form a separate transactional workflow.

Do not mirror every `UserManager` or `RoleManager` method. Application interfaces expose only approved use cases and return application-owned results. Infrastructure implements them with ASP.NET Core Identity, JWT libraries, `AuthDbContext`, and cryptographic services.

## 12. Clean Architecture Placement

| Layer | Authentication responsibility |
| --- | --- |
| Domain | No Identity, JWT, claims, HTTP, `UserManager`, or credential model. Domain receives already established actor IDs where behavior requires them. |
| Application | `ICurrentUser`, focused identity/token contracts, login/refresh/provisioning commands, DTOs/results, authorization requirements, and resource-policy orchestration. |
| Infrastructure | `ApplicationUser`, `AuthDbContext`, Identity stores, `UserManager`, `RoleManager`, password verification, JWT signing, refresh persistence, and domain-link/assignment readers. |
| API | Authentication/authorization registration, JWT bearer configuration, auth endpoints/contracts, coarse policies, claim-to-current-user adapter, and Problem Details. |

`ExaminationDbContext` remains the Database First domain persistence context. `AuthDbContext` owns only the `auth` schema. The API references Infrastructure only at the composition root.

## 13. Authorization Policies

Use these policy names as stable intent names; implementation may use handlers rather than role attributes for resource checks:

| Policy | Check and placement |
| --- | --- |
| `StudentOnly` | API verifies authenticated Student role and valid student link claim. |
| `InstructorOnly` | API verifies authenticated Instructor role and valid instructor link claim. |
| `AdminOnly` | API verifies authenticated Admin role. |
| `InstructorAssignedToCourse` | Application/resource handler loads current `INSTRUCTOR_COURSE` assignment for actor and course. |
| `StudentOwnsAttempt` | Application/resource handler loads attempt and compares its student to `ICurrentUser.StudentId`. |
| `StudentOwnsResult` | Application/resource handler applies the same ownership rule to the result's attempt. |
| `CanViewCorrectAnswers` | Application requires own graded attempt, or approved instructor/admin reporting scope. |
| `CanViewSensitiveProfile` | API coarse role plus Application self/scoped-staff field check. |
| `CanViewIntegrityDiagnostics` | Admin, or explicitly approved instructor scope for non-sensitive course diagnostics. |

Use role policies at the API boundary for fast rejection. Database-dependent authorization runs inside the Application use case before mutation or sensitive projection. A missing resource returns not found only where disclosure is safe; an existing resource outside the caller's scope returns forbidden according to the endpoint's enumeration policy.

## 14. Authentication Endpoints

| Endpoint | Auth | Request | Response | Security notes |
| --- | --- | --- | --- | --- |
| `POST /api/auth/login` | Anonymous | login name/email, password | access token, expiry, refresh token, safe account/role summary | Uniform credential failure; rate limit; apply lockout; never log secrets. |
| `POST /api/auth/refresh` | Anonymous with refresh credential | refresh token | rotated access/refresh pair and expiry | Hash lookup, atomic rotation, reuse-family revocation, revalidate role/link/account. |
| `POST /api/auth/logout` | Authenticated; refresh credential supplied securely | refresh token or current session identifier | `204 No Content` | Revoke the matching session/family; response remains idempotent. |
| `GET /api/auth/me` | Authenticated | none | user ID, role, linked student/instructor ID, safe display data | No password, token, contact data, or permissions inferred from mutable assignments. |
| `POST /api/auth/register/student` | Anonymous only if approved | approved registration and credential fields; no role/link authority | safe account identity and activation outcome | Rate limit; role forced to Student; no legacy password copy; transaction/provisioning policy required. |

Admin provisioning belongs under a protected administrative account endpoint, separate from `/api/auth/login` and public registration. Password reset, email confirmation, and multi-factor endpoints are later endpoint decisions unless selected as release requirements during security review.

## 15. Interaction With Existing Business Features

- **Question Bank:** authenticated Instructor -> `InstructorId` -> current `INSTRUCTOR_COURSE` check -> permitted create/edit -> question usage lock check.
- **Exam Authoring:** authenticated Instructor -> `InstructorId` -> course assignment check -> draft create/compose/generate/activate.
- **Exam Attempts:** authenticated Student -> `StudentId` -> active `STUDENT_COURSE` enrollment -> active exam and attempt-limit checks -> start/resume.
- **Answering:** authenticated Student -> attempt ownership -> in-progress/deadline/alignment checks -> answer upsert.
- **Results:** Student gets own attempt only and correct answers only after `graded`; Instructor requires assigned-course scope; Admin access follows protected reporting policy.
- **Profiles and enrollments:** Student identity comes from `ICurrentUser`; request-provided IDs never grant self-service authority.

## 16. Password and Credential Migration Policy

Recommend independent Identity account provisioning with forced account activation/password setup. Do not copy `STUDENT.password` into Identity and do not assume it can be verified securely.

Before any controlled credential migration is considered, verify and document:

- whether the legacy value is plaintext, reversible encryption, or a recognized password hash;
- algorithm, work factor, salt format, encoding, and comparison behavior;
- whether the format resists offline cracking by current standards;
- whether a custom Identity password hasher can verify once and rehash immediately;
- account-to-student uniqueness and login normalization conflicts;
- legal/security approval for handling the legacy credential material.

If any item is unknown or inadequate, provision the Identity account independently and require password creation through a single-use, expiring activation/reset flow. After transition, `STUDENT.password` remains unused legacy data until a separately approved remediation removes or protects it.

## 17. Security Rules

- Hash passwords only through ASP.NET Core Identity's configured password hasher.
- Require HTTPS and HSTS outside local development.
- Store signing keys, database credentials, and token secrets in environment-specific secret stores; never commit them.
- Validate JWT signature, issuer, audience, lifetime, algorithm, and required claims.
- Enable lockout and rate limits for login, refresh, registration, and reset flows.
- Rotate refresh tokens, detect reuse, and revoke token families.
- Revoke all refresh sessions on password reset, account disablement, role change, or identity-link change.
- Never log passwords, raw access/refresh tokens, authorization headers, or sensitive PII.
- Put no sensitive PII or mutable course/enrollment authorization data in JWTs.
- Never accept a role, StudentId, or InstructorId from a client as authorization evidence.
- Keep access tokens short-lived and define signing-key rotation and incident revocation procedures before production.
- Return `401 Unauthorized` when authentication is absent or invalid; return `403 Forbidden` when an authenticated actor lacks permission.
- Never expose correct answers through an active-attempt contract.

## 18. Error Model

| Error code | HTTP | Meaning |
| --- | --- | --- |
| `InvalidCredentials` | 401 | Login failed; response does not identify whether the account exists. |
| `AccountLocked` | 401 | Identity lockout is active. Use the same public response shape as invalid credentials; retain the specific reason only in protected operational telemetry. |
| `Unauthenticated` | 401 | Missing, malformed, expired, or otherwise invalid access token. |
| `Forbidden` | 403 | Valid identity lacks role, ownership, assignment, or field scope. |
| `InvalidRefreshToken` | 401 | Refresh credential is malformed or unknown. |
| `ExpiredRefreshToken` | 401 | Refresh lifetime ended. |
| `RevokedRefreshToken` | 401 | Token was revoked or already rotated; reuse handling may revoke its family. |
| `IdentityLinkInvalid` | 403 | Required student/instructor link or referenced domain row is invalid. |
| `RoleMismatch` | 403 | Role and link fields violate the MVP account invariant. |

Return RFC-style Problem Details with stable application error codes, trace ID, and safe detail. SQL/Identity internals, usernames, link existence, tokens, and stack traces are excluded.

## 19. Testing Strategy

### Unit tests

- role/link invariant matrix and exactly-one-primary-role rule;
- current-user claim parsing results, including malformed/missing IDs;
- token configuration validation and claim construction without sensitive fields;
- refresh rotation, expiry, revocation, and family reuse decisions;
- resource policies for course assignment, attempt/result ownership, correct-answer access, and profile fields;
- error-to-HTTP mapping decisions.

### Integration tests

- Identity user/role/link persistence in the isolated `auth` schema;
- unique filtered student/instructor links;
- password hashing/verification and lockout through Identity;
- JWT signature, issuer, audience, expiry, algorithm, and key-rotation configuration;
- atomic refresh rotation and concurrent reuse detection;
- refresh revocation on security-sensitive account changes;
- linked domain row existence and role/link inconsistency behavior across both contexts;
- generated auth migration contains only `auth` objects and uses its own migration history;
- domain Database First context remains unchanged and has no migration operations.

### API tests

- login success, uniform failure, lockout, logout, `/me`, refresh rotation/reuse/revocation;
- Student cannot call Instructor endpoints; Instructor cannot call Admin endpoints;
- Instructor A cannot author for Instructor B's unassigned course;
- Student A cannot access Student B's attempt/result;
- spoofed student/instructor IDs do not bypass authenticated identity;
- Student/Instructor roles with missing or dangling links are rejected;
- inconsistent role/link combinations are rejected;
- active attempt responses never expose correct answers;
- expired/invalid access tokens return 401 and valid-but-forbidden actors return 403;
- passwords and tokens do not appear in responses, errors, or captured application logs.

## 20. Implementation Sequence

1. **Phase 0A — Authentication foundation:** add Application contracts, current-user model, role/link invariants, policy names, error codes, configuration contracts, and security-focused tests. No persistence change.
2. **Phase 0B — Identity persistence and JWT infrastructure:** add `ApplicationUser`, `AuthDbContext`, explicit `auth` mappings, refresh-token model/store, Identity services, token signing/validation, and isolated auth migration design. Generate/apply auth migrations only after separate database-change approval.
3. **Phase 0C — Authentication endpoints and RBAC:** implement login, refresh, logout, `/me`, Admin provisioning, and student registration only if approved; configure coarse policies and lockout/rate limits.
4. **Phase 1 — Existing Database-First Infrastructure:** scaffold and verify the 18 operational domain tables without migrations.
5. **Phase 2 onward:** follow `IMPLEMENTATION_PLAN.md`, with protected reference endpoints depending on 0C, Question Bank and Exam Authoring depending on Instructor identity plus assignment checks, and Exam Attempts depending on Student identity plus enrollment checks.

Phase 0B may be coded before an auth migration is applied, but integration/API completion is blocked until an isolated auth database is approved and available. No protected feature is released with a placeholder identity.

## 21. Final Decisions and Remaining Questions

### Approved decisions

- ASP.NET Core Identity is authoritative for accounts/passwords; JWT access and rotating refresh tokens authenticate API clients.
- Identity shares `ITI_EXAMINATION` under the `auth` schema using a separate `AuthDbContext` and migrations boundary.
- `ApplicationUser` uses nullable direct `StudentId`/`InstructorId` links with unique filtered indexes and application-level domain-row validation.
- MVP roles are Admin, Instructor, and Student, with exactly one primary role per account.
- Resource authorization rechecks current course assignment, enrollment, ownership, state, and disclosure rules from SQL Server.
- Refresh tokens use a dedicated Identity-owned table and are stored only as hashes.
- Legacy student passwords are never copied automatically or treated as the new credential store.

### Remaining decisions

- whether student self-registration creates a new `STUDENT` row or activates a pre-provisioned record;
- approved login identifier and whether email confirmation is required;
- password, lockout, access-token, refresh-token, and clock-skew configuration values after security review;
- asymmetric versus symmetric signing and the production key-management/rotation service;
- whether logout revokes one refresh session or all sessions by default;
- whether multi-factor authentication is required for Admin accounts in the MVP;
- administrative provisioning endpoint details and bootstrap process;
- whether outward lockout responses are distinct or intentionally indistinguishable from invalid credentials.

### Security risks

- legacy password data remains sensitive even though the new API does not use it;
- short-lived JWTs cannot be instantly revoked without a denylist or per-request account-version check;
- missing database FKs permit dangling Identity links unless provisioning and login/refresh validation are correct;
- stale `INSTRUCTOR_COURSE` claims would over-authorize, so assignments must never be token claims;
- cross-context student registration can leave partial state unless one transaction or a fail-closed provisioning workflow is used.

### Implementation blockers

- explicit approval to create the `auth` schema/tables and apply the isolated Identity migration;
- selection of student account activation/provisioning behavior;
- secure Admin bootstrap and signing-key storage for each deployed environment;
- a non-production SQL Server database for Identity migration and integration testing.

These blockers do not authorize implementation or database changes. They define what must be settled before the corresponding phase can be completed.
