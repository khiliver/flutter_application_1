# BU.Library Firestore Database Documentation (Kotlin)

This document starts the Firestore database documentation for the BU.Library project.

## Firebase Project
- Project display name: BU.Library
- Database: Cloud Firestore
- SDK style: Kotlin + Firebase KTX APIs

## Firestore Collections (Initial)

### 1) accounts
Purpose: stores app login and role data.

Recommended document ID:
- lowercase email (example: `ada@example.com`)

Recommended fields:
- `email` (String)
- `emailLower` (String)
- `password` (String) (replace with Firebase Auth in production)
- `name` (String)
- `role` (String) values: Admin, Librarian, User, Super Admin
- `roleLower` (String)
- `userType` (String, nullable)
- `updatedAt` (Timestamp, server generated)

## Kotlin Setup

```kotlin
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase

val db = Firebase.firestore
```

## Kotlin CRUD Examples

### Create or update an account document

```kotlin
val email = "ada@example.com"
val account = hashMapOf(
    "email" to email,
    "emailLower" to email.lowercase(),
    "password" to "temporary-password",
    "name" to "Ada Lovelace",
    "role" to "User",
    "roleLower" to "user",
    "userType" to "Student"
)

db.collection("accounts")
    .document(email.lowercase())
    .set(account)
    .addOnSuccessListener {
        // Success handling
    }
    .addOnFailureListener { e ->
        // Error handling
    }
```

### Read one account by email

```kotlin
val email = "ada@example.com"

db.collection("accounts")
    .document(email.lowercase())
    .get()
    .addOnSuccessListener { snapshot ->
        if (snapshot.exists()) {
            val name = snapshot.getString("name")
            val role = snapshot.getString("role")
            // Use loaded values
        }
    }
    .addOnFailureListener { e ->
        // Error handling
    }
```

### Query all Super Admin accounts

```kotlin
db.collection("accounts")
    .whereEqualTo("roleLower", "super admin")
    .get()
    .addOnSuccessListener { querySnapshot ->
        for (doc in querySnapshot.documents) {
            val email = doc.getString("email")
            // Process each super admin
        }
    }
    .addOnFailureListener { e ->
        // Error handling
    }
```

### Delete an account by email

```kotlin
val email = "ada@example.com"

db.collection("accounts")
    .document(email.lowercase())
    .delete()
    .addOnSuccessListener {
        // Success handling
    }
    .addOnFailureListener { e ->
        // Error handling
    }
```

## Suggested Security Rules (Starter)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /accounts/{accountId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Next Collections To Document
- `reservations`
- `announcements`
- `notifications`
- `permissions`

## Notes
- This codebase now starts migrating from local SharedPreferences storage to Firestore.
- Password should be migrated to Firebase Authentication or hashed storage as a follow-up security task.
