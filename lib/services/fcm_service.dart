import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

/// Handles Firebase Cloud Messaging: permission, token, and message handling.
/// Foreground messages are shown via [NotificationService]. Background/terminated
/// are handled by the system or the background handler.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  /// Call once after [Firebase.initializeApp]. Requests permission (iOS) and sets up listeners.
  Future<void> initialize() async {
    if (_initialized) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      // Optional: send token to your server for targeting (e.g. save to Firebase).
      // debugPrint('FCM token: $token');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      // Optional: update token on server.
    });

    // Foreground: show via local notification so user sees it.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // User tapped notification (app was in background).
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _initialized = true;
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'GIGA ETH Mining';
    final body = notification?.body ?? message.data['body'] ?? '';
    if (body.isNotEmpty) {
      NotificationService.instance.showFcmNotification(title: title, body: body);
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    // Optional: navigate to a specific screen based on message.data.
    // e.g. if (message.data['screen'] == 'rewards') => navigate to rewards.
  }

  /// Call from your login flow to get the current FCM token (e.g. save to Firebase for targeting).
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Subscribe to a topic (e.g. 'all_users' or 'promos'). Server can send to topic.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Call when app starts to handle notification that opened the app (terminated state).
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();
}
