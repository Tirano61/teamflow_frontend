# TeamFlow Frontend — Claude Code Project Context

## 1. Project overview

TeamFlow is the Flutter client for a multi-organization collaborative work management platform.

It allows users to work within organizations, switch between organizations they belong to, access organization-specific workspaces, organize work, participate in discussions, manage assignments and collaborate around ongoing activities.

TeamFlow is intended to support different types of organizations and workflows.

It is NOT limited to software development teams.

Do not assume that WorkModule, Component, Discussion, Assignment or workflow states represent software-development concepts unless the specific feature explicitly establishes that meaning.

The frontend is built with:

* Flutter
* Dart
* BLoC
* DDD-style feature architecture
* HTTP REST API
* Firebase integration

Use BLoC.

Do NOT introduce Cubit.


---

## 2. Architecture

Features generally follow:

features/<feature>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/

Respect the existing structure.

Do not move business logic into Widgets.

---

## 3. Layer responsibilities

### Models

JSON parsing and serialization belong in Models.

Use:

- `Model.fromJson`
- model serialization where required

Entities must NOT parse JSON.

### Datasources

Datasources perform HTTP/data access.

They return Models/data structures according to the existing architecture.

### Repositories

Repositories map datasource exceptions to the project's Failure hierarchy.

Use the existing failure mapper/conventions.

### Use cases

Use cases expose domain operations to presentation.

### BLoC

Business/presentation state logic belongs in BLoCs.

Do NOT use Cubit.

### Widgets

Widgets should focus on rendering and user interaction.

Do not make Widgets responsible for:

- JSON parsing
- HTTP calls
- tenant resolution
- repository logic

---

## 4. Multi-organization architecture

TeamFlow is MULTI-ORGANIZATION.

The authenticated user may belong to:

- zero organizations
- one organization
- multiple organizations

The active organization is represented at runtime through:

`OrganizationContext`

Tenant-aware datasources resolve the current organization from this context.

Do NOT pass `organizationId` through Widgets, BLoC events or use cases unless an explicit future requirement changes this architecture.

Tenant datasources should resolve it at request time.

Conceptually:

`String get _organizationId => _organizationContext.organizationId;`

Do NOT cache the organization id in the datasource constructor.

The active organization can change while the application is running.

---

## 5. Active organization persistence

The selected organization is persisted using the existing:

- `ActiveOrganizationStorage`
- `ActiveOrganizationResolver`

Only the organization ID is persisted.

Do not persist duplicated organization information such as:

- name
- slug
- role
- organization list

A persisted organization ID is a preference, NOT authorization.

After `/me/context`, the ID must be validated against the organizations returned by the backend.

If it is no longer valid, it must not be used.

---

## 6. Organization selection rules

Current behavior:

### Zero organizations

No active organization.

The user is routed to the no-organization flow.

### One organization

Automatically select it.

### Multiple organizations

Restore the persisted organization if it is still valid.

Otherwise show organization selection.

Do not invent an organization.

---

## 7. Post-auth navigation

Post-auth destination logic is centralized.

Relevant concepts:

- `PostAuthDestination`
- `PostAuthDestinationResolver`
- `AuthGatePage`

Do not duplicate organization-count/navigation rules inside pages.

Widgets must not manually reproduce the post-auth decision tree.

---

## 8. User context

`GET /me/context` is the source of authenticated organization context.

The user context includes concepts such as:

- authenticated user
- organizations
- organization roles
- pending invitations

The endpoint is global and does NOT require an organizationId.

It must be loaded before entering tenant Workspace functionality.

If user context cannot be resolved, do not silently enter Workspace with an empty tenant.

---

## 9. Organization switching

Users with multiple organizations can change the active organization from within TeamFlow.

The existing organization selector is reused.

Do not create a second independent organization-selection implementation.

Selection is applied through the Auth flow / `AuthOrganizationSelected`.

Widgets must not mutate `OrganizationContext` directly.

When active organization changes, the application resets the relevant navigation stack so tenant-scoped BLoCs are disposed and recreated.

Do not preserve tenant data from the previous organization.

---

## 10. Tenant BLoCs

Tenant-specific BLoCs are generally registered as factories and created by routes.

Examples include:

- DiscussionBloc
- DiscussionMessageBloc
- WorkModuleBloc
- ComponentBloc
- TagBloc
- MembershipBloc

Changing organization must not leave data from the previous tenant visible.

Before creating new global/singleton state, consider whether it contains tenant-specific data.

---

## 11. Workspace terminology

Use current domain terminology:

- Workspace
- WorkModule
- Component

Legacy domain terminology must not be reintroduced:

- Develop Workflow
- Application for WorkModule
- Indicator for Component

Legitimate Flutter/API terms such as:

- CircularProgressIndicator
- LinearProgressIndicator
- application/json

are obviously not legacy domain references.

---

## 12. Tenant endpoints

Workspace tenant routes follow:

`/organizations/{organizationId}/workspace/...`

Tenant resources include:

- modules
- components
- tags
- developers
- discussions
- discussion messages
- discussion assignments
- discussion context

`ApiEndpoints` should remain the central definition of API paths.

Do not construct tenant URLs manually inside Widgets.

---

## 13. Global endpoints

Some endpoints intentionally do NOT use organizationId.

Examples:

- `/auth/login`
- `/me/context`
- `/users/search`
- `/workspace/devices`
- `/workspace/notifications`
- `/workspace/notifications/test`

Do not move them under an organization merely for consistency.

---

## 14. HTTP authentication

Protected routes must receive JWT according to the existing `HttpRestClient` rules.

When adding a new top-level authenticated API prefix, verify that the authentication routing logic recognizes it.

Do not assume that defining an endpoint in `ApiEndpoints` automatically makes it authenticated.

Preserve existing:

- 401 session expiration behavior
- token clearing behavior
- session signals
- 403 handling

unless explicitly requested to change them.

---

## 15. WorkModules and Components

Current domain naming:

- WorkModule
- Component

The API contract uses:

- modules
- module
- components
- component
- moduleIds
- componentIds

Do not reintroduce:

- applications
- applicationIds
- indicators
- indicatorIds

for TeamFlow domain contracts.

---

## 16. Discussions

Discussions are tenant-scoped.

Discussion context can contain:

- WorkModules
- Components
- Tags

Filters and request bodies use:

- moduleIds
- componentIds
- tagIds

Discussion detail, messages and assignments must always operate against the active organization.

Do not manually build endpoint URLs in presentation code when the datasource/API endpoint layer can own them.

---

## 17. Memberships

The memberships feature displays members of the active organization.

Organization membership roles currently include:

- OWNER
- ADMIN
- DEVELOPER
- MEMBER

Backend authorization is authoritative.

Frontend role checks are only used to improve UX/visibility.

Do not assume hiding a button is sufficient security.

---

## 18. Internal invitations

TeamFlow invitations target a specific registered User.

Invitation creation uses:

`userId`

not arbitrary free-form email.

User search is global through:

`GET /users/search`

The invitation UI must require explicit selection of a search result.

Never use the raw search text as the invitation recipient.

Assignable invitation roles:

- MEMBER
- DEVELOPER
- ADMIN

Do not offer OWNER.

---

## 19. Invitation management

OWNER/ADMIN can access organization invitation administration.

The existing feature:

`organization_invitations`

handles:

- accepting personal invitations
- creating invitations
- listing organization invitations
- cancelling pending invitations

Do not create a parallel invitation feature unnecessarily.

Administrative invitation states include:

- PENDING
- ACCEPTED
- EXPIRED
- CANCELLED

Legacy invitations may have:

`invitedUser == null`

In that case the email remains the recipient identifier.

---

## 20. Creating organizations

Organization creation already exists.

Do not create another organization-creation flow unless explicitly requested.

After organization/invitation changes, refresh `/me/context` through the existing Auth flow rather than manually reproducing organization-selection logic.

---

## 21. Firebase

Firebase is already configured for TeamFlow.

Project:

`teamflow-d217e`

Platforms include:

- Android
- iOS
- Web

Do not recreate Firebase configuration or replace `firebase_options.dart` unless explicitly requested.

---

## 22. API endpoint changes — IMPORTANT

When frontend work requires a new or changed backend endpoint, explicitly identify that requirement.

Do not silently invent a backend contract.

If backend code is available in the workspace, inspect the real controller/DTO/service before assuming the request or response format.

Frontend implementation must follow the REAL backend response.

Do not compensate for backend uncertainty with speculative JSON parsing.

---

## 23. Endpoint documentation and Postman

Backend endpoint documentation is maintained in:

`docs/workspace-endpoints.md`

Postman collection:

`docs/workspace.postman_collection.json`

If the task includes backend endpoint changes and those files are part of the available repository/workspace, they MUST be updated.

Any added/modified endpoint must be reflected in BOTH:

- endpoint documentation
- existing Postman collection

Do not create duplicate documentation or another Postman collection.

If working only inside the frontend repository and the backend/docs are unavailable, report explicitly that the corresponding backend documentation/Postman update is required rather than pretending it was done.

---

## 24. Error handling

Use the existing:

- exceptions
- Failure classes
- failure mapper
- session-expiration flow

Do not show raw technical exceptions to users when an existing Failure mapping applies.

Handle domain-specific HTTP codes only when the backend contract actually defines them.

Do not invent backend error semantics.

---

## 25. UI rules

Preserve the current TeamFlow visual language unless the task explicitly requests redesign.

Do not perform broad UI redesign while implementing functional changes.

Keep pages responsive.

Avoid putting complex logic directly in build methods.

Reuse existing widgets and flows when possible.

---

## 26. Dependency injection

Use the existing service locator conventions.

Respect existing lifecycle choices:

- singleton/lazy singleton for appropriate infrastructure/domain services
- factory for tenant/presentation BLoCs where currently used

Do not convert tenant BLoCs into global singletons without a strong explicit reason.

---

## 27. Coding rules

Keep changes focused.

Do not refactor unrelated code.

Do not rename unrelated files.

Do not introduce new packages when the existing stack can solve the problem.

Before adding a class, use case, BLoC or feature, search for an existing equivalent.

Prefer extending the existing architecture over creating parallel implementations.

Do not put logic in Widgets merely because it is faster.

---

## 28. Verification

After Flutter changes run:

`flutter analyze`

Expected result:

`No issues found!`

Do NOT run:

`flutter test`

unless explicitly requested.

Do not create tests unless explicitly requested.

Formatting should be limited to files actually changed.

Do not reformat the entire project.

---

## 29. Before implementing a prompt

First inspect the repository.

Determine:

1. What already exists.
2. What is partially implemented.
3. What is actually missing.
4. What contracts the backend really exposes.
5. Whether the requested change affects multi-tenancy.
6. Whether the change affects authentication/authorization.
7. Whether endpoints/docs/Postman need updates.

Do not blindly implement the prompt if the functionality already exists.

Adapt the implementation to the current repository state.

---

## 30. Completion report

At the end of a task report:

1. Files created/modified.
2. Structure/architecture used.
3. Data flow.
4. organizationId handling when applicable.
5. Backend endpoint(s) consumed or changed.
6. Authorization/role behavior.
7. Tenant isolation behavior.
8. Error handling.
9. Documentation/Postman updates if applicable.
10. `flutter analyze` result.
11. Anything deliberately left outside scope.

Be explicit about deviations from the requested scope.

Do not claim something was implemented unless it exists in the repository.


## Backend API contract — SOURCE OF TRUTH

When implementing or modifying frontend functionality that communicates with the backend, do NOT guess endpoint paths, request bodies or response structures.

The canonical backend API references are:

* `docs/workspace-endpoints.md`
* `docs/workspace.postman_collection.json`

When these files are available in the workspace, Claude MUST inspect them before implementing or modifying an HTTP integration.

### Use `docs/workspace-endpoints.md` to determine

* HTTP method
* endpoint path
* whether the endpoint is global or tenant-scoped
* path parameters
* query parameters
* request body
* response structure
* authentication requirements
* Membership/role requirements
* expected status codes
* validation and conflict behavior

### Use `docs/workspace.postman_collection.json` to verify

* the exact request being sent
* path and query parameters
* request body examples
* authentication headers
* collection variables
* realistic request sequences
* successful scenarios
* expected failure scenarios

The frontend implementation must conform to these backend contracts.

Do NOT invent:

* endpoint paths
* JSON property names
* response wrappers
* status-code semantics
* role rules
* tenant behavior

just to make the frontend implementation work.

---

## Contract verification order

Before implementing a new HTTP integration:

1. Read `docs/workspace-endpoints.md`.
2. Inspect the corresponding request in `docs/workspace.postman_collection.json`.
3. Inspect existing `ApiEndpoints`.
4. Inspect the relevant RemoteDataSource.
5. Inspect existing Models and their JSON parsing.
6. If backend source code is available and something is unclear, inspect the real controller, DTO and service.

If the documentation and backend implementation disagree, do NOT silently choose one.

Identify the inconsistency and base the frontend on the actual backend behavior, while reporting that the backend documentation must be corrected.

---

## ApiEndpoints

All backend routes consumed by Flutter must be represented through the existing `ApiEndpoints` abstraction.

Do not scatter literal backend paths throughout:

* pages
* widgets
* BLoCs
* repositories

Tenant routes must follow the contract documented by the backend.

Organization-scoped Workspace routes generally use:

`/organizations/{organizationId}/workspace/...`

Global endpoints must remain global when documented that way.

Do not add `organizationId` to an endpoint merely because the current screen belongs to an organization.

---

## Request and response models

Before creating or modifying a Model:

1. Check the documented response in `docs/workspace-endpoints.md`.
2. Check the Postman request/response expectations when available.
3. Match the actual backend property names exactly.

JSON parsing belongs in Models.

Do not add fallback parsing for speculative field names unless compatibility with an existing backend response actually requires it.

For example, do NOT parse multiple invented alternatives such as:

`json['id'] ?? json['membershipId'] ?? json['member_id']`

unless those alternatives are genuinely part of an existing compatibility requirement.

The frontend should model the real API contract, not try to guess every possible backend response.
