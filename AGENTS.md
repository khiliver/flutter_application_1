# AGENTS

## Purpose
This file defines how coding agents should work in this repository.
Follow these rules to make safe, minimal, and testable changes.

## Project Snapshot
- Stack: Flutter (Dart), Material UI.
- Data layer: local persistence via SharedPreferences.
- Architecture: screen-driven UI with singleton storage services.
- Main entry and route shell: lib/main.dart.

## Code Map
- App bootstrap and route wiring: lib/main.dart
- Screens: lib/screens/
- Services (local storage and business logic): lib/services/
- Reusable UI widgets: lib/widgets/
- Theme and visual defaults: lib/theme/app_theme.dart
- Domain models: lib/models/

## Working Rules For Agents
- Keep changes focused and small. Do not refactor unrelated files.
- Preserve existing style and naming unless task explicitly asks otherwise.
- Keep helper methods at class scope in Flutter screens.
- Do not declare local functions inside widget children lists.
- Avoid broad formatting changes; format only edited Dart files.

## Role And Access Behavior
Role logic is string-based in multiple places. Treat these values as sensitive:
- Admin
- Librarian
- User

When editing role logic:
- Preserve current behavior unless the task is a role-system refactor.
- Check manager-only and user-only paths after changes.

## Data Persistence Rules
SharedPreferences-backed storage lives in service singletons. Keep these patterns:
- JSON encode/decode for persisted entities.
- Key constants with version suffixes (example: _v1).
- Read-modify-write flows that preserve existing stored data shape.

If a model schema changes:
- Update toJson/fromJson and all affected service reads/writes together.
- Maintain backward compatibility when possible.
- Document migration impact in the change summary.

## High-Risk Areas
- Dashboard: charts, announcement posting, and account management in one screen.
- Reservations: role-based CRUD and status transitions.
- Notifications: admin/global versus recipient-targeted visibility.
- Login and signup flow: auth checks, route arguments, and account creation.

## Validation Checklist (Required)
Run after code edits:
1. flutter analyze
2. flutter test
3. dart format on changed Dart files

Manual smoke checks for touched features:
1. Login and signup flow
2. Role-based dashboard/tab behavior
3. Reservations add/edit/cancel/delete as applicable
4. Notifications behavior for affected role(s)

## Definition Of Done
- No new analyzer issues in changed files.
- Changed files are formatted.
- Affected user flow is manually validated.
- No unrelated file changes are included.

## Common Change Playbooks
### Add Persisted Field
1. Update model fields and serialization.
2. Update storage service read/write logic.
3. Update UI input and rendering.
4. Validate with existing local data.

### Add New Screen Capability
1. Confirm route or tab integration in lib/main.dart.
2. Keep role gating explicit and test both allowed and blocked paths.
3. Keep state updates mounted-safe after async operations.

### Refactor Role Checks
1. Introduce centralized helper first.
2. Migrate comparisons incrementally.
3. Verify admin, librarian, and user behavior before finalizing.