# MedReminder – Firebase Setup Guide

Project Firebase ID: **medreminder-ee920**

## 1. Prerequisites

- Flutter SDK (stable) installed
- Android Studio / VS Code
- Firebase account
- Node.js (for Firebase CLI)

```bash
flutter doctor
dart --version
```

## 2. Firebase Console Setup

1. Open [Firebase Console](https://console.firebase.google.com/) → project **medreminder-ee920**
2. Enable **Authentication** → Email/Password + Google
3. Create **Cloud Firestore** database (production mode, then deploy rules)
4. Enable **Firebase Storage**
5. Enable **Cloud Messaging** (FCM)

## 3. FlutterFire (already configured)

Config files in this repo:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

Reconfigure if needed:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=medreminder-ee920
```

## 4. Deploy Security Rules

```bash
npm install -g firebase-tools
firebase login
# Project is set in .firebaserc (default: medreminder-ee920)
firebase use medreminder-ee920
firebase deploy --only firestore:rules,storage
```

If you see **No currently active project**, run `firebase use medreminder-ee920` once, or pass `--project medreminder-ee920` on every command.

Rule files:

- `firestore.rules`
- `storage.rules`

## 5. Firestore Indexes

Create composite indexes in Console when prompted, or add to `firestore.indexes.json`:

| Collection   | Fields                                      |
|-------------|---------------------------------------------|
| medicines   | userId ASC, isActive ASC, createdAt DESC    |
| prescriptions | userId ASC, createdAt DESC              |
| reminders   | userId ASC, scheduledAt ASC                 |

## 6. Android Setup

1. `android/app/google-services.json` is present
2. `build.gradle.kts` applies `com.google.gms.google-services`
3. For Google Sign-In, add SHA-1 in Firebase → Project Settings → Android app:

```bash
cd android && ./gradlew signingReport
```

4. Run:

```bash
flutter pub get
flutter run
```

## 7. iOS Setup (optional)

```bash
flutterfire configure
```

Add `GoogleService-Info.plist` to `ios/Runner/` and enable capabilities in Xcode.

## 8. FCM Setup

1. Firebase Console → Cloud Messaging
2. Android: notifications permission in `AndroidManifest.xml` (done)
3. App stores FCM token in `users/{uid}.fcmToken` on login

## 9. Collections Structure

```
users/{uid}
medicines/{medicineId}
reminders/{reminderId}
prescriptions/{prescriptionId}
emergency_contacts/{contactId}
notifications/{notificationId}
emergency_alerts/{alertId}
reports/{reportId}
family_links/{linkId}
```

## 10. Test Flow

1. Run app → complete onboarding → Register
2. Login → Dashboard shows your name
3. Tap **+** → Add Medication → appears in Medical tab
4. Mark medicine as **Taken** → logged in `reminders`
5. Emergency tab → SOS sends alert to Firestore

## 11. Troubleshooting

| Issue | Fix |
|-------|-----|
| `PERMISSION_DENIED` | Deploy `firestore.rules` |
| Google Sign-In fails | Add SHA-1, enable Google provider |
| Index required | Create composite index from error link |
| Login works but no profile | Auto-created on first login |

## 12. Project Architecture

```
lib/
├── core/           # constants, error helpers
├── models/         # Firestore models
├── services/       # Firebase business logic
├── providers/      # Provider state (Auth, Medicine)
├── screens/        # Existing UI (wired to backend)
├── widgets/        # auth_wrapper
└── main.dart       # Firebase init + providers
```
