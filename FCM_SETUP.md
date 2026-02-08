# Firebase Cloud Messaging (FCM) – Push notifications

Push notifications from Firebase Cloud Messaging are integrated. Below is what’s done in the app and what you need to do in Firebase and Xcode.

## What’s integrated in the app

- **firebase_messaging** dependency and **FcmService**:
  - Requests notification permission (iOS).
  - Gets FCM token (use `FcmService.instance.getToken()` to send to your server if needed).
  - **Foreground**: when a message is received while the app is open, it is shown as a local notification.
  - **Background / terminated**: FCM shows the notification; when the user taps it, the app opens.
- **Background handler** registered in `main.dart` so data messages can be handled when the app is in the background or closed.
- **NotificationService** has `showFcmNotification()` for foreground FCM messages.

## What you need to do

### 1. Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/) → your project.
2. Go to **Build** → **Cloud Messaging**.
3. (Optional) Under **Cloud Messaging API (Legacy)** or **FCM**, make sure the API is enabled.

### 2. Send a test notification

1. In Firebase Console → **Engage** → **Messaging** (or **Cloud Messaging**).
2. Click **Create your first campaign** or **New campaign** → **Firebase Notification messages**.
3. Enter **Notification title** and **Notification text**.
4. Choose your app (Android and/or iOS).
5. Send now or schedule.

You can also send via the **Cloud Messaging** tab using the **Send test message** option and your FCM token (from `FcmService.instance.getToken()` in the app).

### 3. iOS: Push Notifications capability and APNs

1. Open `ios/Runner.xcworkspace` in **Xcode**.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **Push Notifications**.
4. In [Firebase Console](https://console.firebase.google.com/) → Project settings → **Cloud Messaging**:
   - Under **Apple app configuration**, upload your **APNs Authentication Key** (.p8) or **APNs certificate** so Firebase can send to iOS devices.

### 4. Android

- No extra steps in code. Ensure `google-services.json` is in `android/app/`.
- For **data-only** messages when the app is in the background, the background handler in `main.dart` runs; you can extend it to show a local notification if needed.

## Optional: topics and token

- **Topics**: e.g. `FcmService.instance.subscribeToTopic('promos');` then send to topic `promos` from Firebase.
- **Token**: call `await FcmService.instance.getToken();` after login and store it in your backend or Firebase (e.g. under `users/<uid>/fcmToken`) to send to a specific device.
