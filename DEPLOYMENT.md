# SOS Arena — Deployment Guide

End-to-end checklist to take the app from a fresh clone to production on Android, iOS, and Web.

## 1. Prerequisites

- Flutter 3.24+ (Dart SDK 3.11.5+)
- Firebase CLI: `npm i -g firebase-tools`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
- For Android: Android Studio + a configured signing key
- For iOS: Xcode 15+, a paid Apple Developer account
- For Web: any static host (Firebase Hosting recommended)

## 2. Install dependencies

```bash
flutter pub get
```

## 3. Firebase project setup

The Firebase project `soso-2c8df` and `lib/firebase_options.dart` are already configured. If you ever need to re-bootstrap:

```bash
flutterfire configure --project=soso-2c8df
```

Enable these products in the Firebase Console:

- Authentication → Sign-in method → **Google**
- Cloud Firestore → Native mode
- Cloud Messaging
- Analytics
- Crashlytics
- Storage

## 4. Environment variables

Edit `.env` at the project root. The keys consumed by the app:

```
APP_NAME=SOS Arena
SUPPORT_EMAIL=support@sosarena.app
GOOGLE_CLIENT_ID_WEB=151581458337-tr0g62nffhjpi10rkbt53tkitm0adcud.apps.googleusercontent.com
GOOGLE_SERVER_CLIENT_ID=151581458337-tr0g62nffhjpi10rkbt53tkitm0adcud.apps.googleusercontent.com
PRESENCE_HEARTBEAT_SECONDS=45
BOARD_SIZE=8
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
```

`.env` is shipped as a Flutter asset (see `pubspec.yaml`). Never commit secrets that should not be visible to clients — the values above are public OAuth/web client IDs which are safe to ship.

## 5. Firestore rules & indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

`firestore.rules` enforces:

- Users can only edit their own profile.
- Friend requests are visible only to the two parties.
- Private chats restricted to participants; messaging strangers is blocked at the app layer (a `chat_rooms` doc with both UIDs is only created once a friend request is accepted).
- Game rooms restricted to the players in `playerIds`.
- Notifications restricted to the recipient.
- Leaderboards are read-only on the client (server-side aggregation recommended).

## 6. Android

1. The plugin `com.google.gms.google-services` must be applied. In `android/build.gradle` (project level) ensure:
   ```gradle
   plugins {
     id "com.google.gms.google-services" version "4.4.2" apply false
     id "com.google.firebase.crashlytics" version "3.0.2" apply false
   }
   ```
2. In `android/app/build.gradle`:
   ```gradle
   plugins {
     id "com.android.application"
     id "kotlin-android"
     id "dev.flutter.flutter-gradle-plugin"
     id "com.google.gms.google-services"
     id "com.google.firebase.crashlytics"
   }
   ```
3. Set `minSdkVersion 23` (required by `firebase_auth`).
4. `google-services.json` is already generated under `android/app/`.
5. To enable Google Sign-In on real devices, add the SHA-1 and SHA-256 of every signing key (debug, upload, release) to Firebase → Project settings → Your Apps → Android, then re-download `google-services.json`:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
6. Build:
   ```bash
   flutter build appbundle --release
   ```

## 7. iOS

1. Run `flutterfire configure --platforms=ios` to drop `GoogleService-Info.plist` into `ios/Runner/`.
2. Open `ios/Runner.xcworkspace` and drag the plist into the Runner target.
3. Add the URL scheme from the plist's `REVERSED_CLIENT_ID` to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array><string>YOUR_REVERSED_CLIENT_ID</string></array>
     </dict>
   </array>
   ```
4. Set deployment target to **iOS 13** (required by `firebase_messaging`).
5. Enable Push Notifications + Background Modes (Remote notifications) capabilities.
6. Build:
   ```bash
   flutter build ipa --release
   ```

## 8. Web

1. `lib/firebase_options.dart` already has the web config.
2. The Google Sign-In meta tag in `web/index.html` is wired to `GOOGLE_CLIENT_ID_WEB`.
3. The FCM service worker is at `web/firebase-messaging-sw.js`.
4. Build and deploy:
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

## 9. Sound assets (manual)

Drop your `.mp3` / `.wav` files into `assets/sounds/` matching the names referenced in `lib/core/services/sound_service.dart`:

```
sos.mp3            – SOS Completed
point.mp3          – Point Earned
win.mp3            – Match Win
lose.mp3           – Match Lost
friend_sent.mp3    – Friend Request Sent
friend_accept.mp3  – Friend Request Accepted
notify.mp3         – Notification Received
rank_up.mp3        – Rank Promotion
```

If a file is missing the player silently no-ops — the rest of the app keeps working.

## 10. Push notifications

- Cloud Messaging requires a server (e.g., a Cloud Function) to send notifications. A minimal sender for friend requests is described in `docs/FCM_SENDER_EXAMPLE.md` (TODO — add a Cloud Function when ready).
- On Android, `flutter_local_notifications` creates the channel `sos_arena_default` on first launch.
- On iOS, permission is requested at first launch.

## 11. Verifying

- Cold start should be < 2 s on a mid-range device.
- Confirm in DevTools → Network: no excessive Firestore listeners; each screen disposes its providers when popped.
- Check `users/{uid}` after sign-in: `fcmToken`, `platform`, `lastTokenUpdate`, `isOnline=true`, `lastSeen` should be present.
- Backgrounding the app should set `isOnline=false`.
