# RISA (Research and Information Search Assistant)

RISA is a Flutter app for library workflows, including account-based access, reservations, announcements, notifications, and role-based dashboards.

## Tech Stack

- Flutter (Dart)
- Material UI with shadcn_ui components
- Local persistence with SharedPreferences

## Features

- Sign in and sign up flow
- Role-based experience for:
	- User
	- Librarian
	- Admin
	- Super Admin
- Reservation management:
	- Create reservations
	- Edit/cancel/delete (based on role and status)
	- Reservation details and status transitions
- Dashboard:
	- Announcement posting
	- Account management (Super Admin controls role edits)
	- Reservation trend line graph connected to reservation data
- Notifications:
	- Global and recipient-targeted notifications
- Profile and edit profile form

## Role Rules

- Sign up creates User accounts only.
- Admin and Librarian roles are assigned by Super Admin from dashboard user management.
- Super Admin accounts are hidden from Admin user list views.

## Project Structure

- lib/main.dart: App bootstrap and route wiring
- lib/screens/: App screens by feature area
- lib/services/: SharedPreferences-backed storage services
- lib/models/: Domain models
- lib/widgets/: Shared/reusable widgets
- lib/theme/: Theme definitions

## Getting Started

### 1) Prerequisites

- Flutter SDK installed
- A device or emulator available

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Run the app

```bash
flutter run
```

## Validate Quality

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Notes on Data

- App data is stored locally using SharedPreferences.
- Reservation and account information persists on device between app restarts.
- Clearing app storage resets locally stored app state.
