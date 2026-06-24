import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmNotification {
  final String title;
  final String body;
  final DateTime timestamp;

  FcmNotification({
    required this.title,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FcmNotification.fromJson(Map<String, dynamic> json) => FcmNotification(
        title: json['title'] as String? ?? 'No Title',
        body: json['body'] as String? ?? 'No Body',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );
}

class FcmService extends ChangeNotifier {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final List<FcmNotification> _notifications = [];

  List<FcmNotification> get notifications => _notifications;

  Future<void> initialize() async {
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await getToken();
      debugPrint("FCM Token: $token");

      setupMessageHandlers();
    } catch (e) {
      debugPrint("Error initializing FCM: $e");
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("Error getting FCM Token: $e");
      return null;
    }
  }

  void setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      _addNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.notification?.title}');
      _addNotification(message);
    });
  }

  void _addNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'No Title';
    final body = message.notification?.body ?? 'No Body';
    _notifications.insert(
      0,
      FcmNotification(
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
