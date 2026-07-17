import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

const _notificationStorageKey = 'fcm_notification_history';
const _notificationHistoryLimit = 50;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _persistRemoteMessage(message);

  debugPrint(
    'Received background message: ${message.notification?.title ?? message.messageId}',
  );
}

class FcmNotification {
  final String? messageId;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? type;
  final String? topic;
  final String? publicationTitle;
  final String? publicationId;
  final int? citations;
  final int? publicationYear;

  FcmNotification({
    this.messageId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type,
    this.topic,
    this.publicationTitle,
    this.publicationId,
    this.citations,
    this.publicationYear,
  });

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'topic': topic,
    'publicationTitle': publicationTitle,
    'publicationId': publicationId,
    'citations': citations,
    'publicationYear': publicationYear,
  };

  factory FcmNotification.fromJson(Map<String, dynamic> json) =>
      FcmNotification(
        messageId: json['messageId'] as String?,
        title: json['title'] as String? ?? 'No Title',
        body: json['body'] as String? ?? 'No Body',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        type: json['type'] as String?,
        topic: json['topic'] as String?,
        publicationTitle: json['publicationTitle'] as String?,
        publicationId: json['publicationId'] as String?,
        citations: _parseInt(json['citations']),
        publicationYear: _parseInt(json['publicationYear']),
      );

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class FcmService extends ChangeNotifier {
  late final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final List<FcmNotification> _notifications = [];

  List<FcmNotification> get notifications => _notifications;

  Future<void> initialize() async {
    try {
      await _loadPersistedNotifications();
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      await _fcm.subscribeToTopic('trend_updates');

      String? token = await getToken();
      debugPrint("FCM Token: $token");

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await setupMessageHandlers();
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

  Future<void> setupMessageHandlers() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        'Notification launched app: ${initialMessage.notification?.title}',
      );
      await _addNotification(initialMessage);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Received foreground message: ${message.notification?.title}');
      await _addNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('Notification opened app: ${message.notification?.title}');
      await _addNotification(message);
    });
  }

  Future<void> _addNotification(RemoteMessage message) async {
    final notification = _notificationFromMessage(message);
    if (_notifications.any(
      (item) =>
          notification.messageId != null &&
          item.messageId == notification.messageId,
    )) {
      return;
    }
    _notifications.insert(0, notification);
    await _saveNotifications(_notifications);
    notifyListeners();
  }

  Future<void> _loadPersistedNotifications() async {
    _notifications
      ..clear()
      ..addAll(await _readNotifications());
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_notificationStorageKey);
    notifyListeners();
  }
}

FcmNotification _notificationFromMessage(RemoteMessage message) {
  final data = message.data;
  return FcmNotification(
    messageId: message.messageId,
    title: message.notification?.title ?? 'No Title',
    body: message.notification?.body ?? 'No Body',
    timestamp: message.sentTime ?? DateTime.now(),
    type: data['type'],
    topic: data['topic'],
    publicationTitle: data['publicationTitle'],
    publicationId: data['publicationId'],
    citations: FcmNotification._parseInt(data['citations']),
    publicationYear: FcmNotification._parseInt(data['publicationYear']),
  );
}

Future<List<FcmNotification>> _readNotifications() async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final encoded = preferences.getStringList(_notificationStorageKey) ?? [];
  final notifications = <FcmNotification>[];
  for (final item in encoded) {
    try {
      notifications.add(
        FcmNotification.fromJson(jsonDecode(item) as Map<String, dynamic>),
      );
    } catch (error) {
      debugPrint('Ignoring invalid stored FCM notification: $error');
    }
  }
  return notifications;
}

Future<void> _saveNotifications(List<FcmNotification> notifications) async {
  final preferences = await SharedPreferences.getInstance();
  final encoded = notifications
      .take(_notificationHistoryLimit)
      .map((item) => jsonEncode(item.toJson()))
      .toList();
  await preferences.setStringList(_notificationStorageKey, encoded);
}

Future<void> _persistRemoteMessage(RemoteMessage message) async {
  final notifications = await _readNotifications();
  final notification = _notificationFromMessage(message);
  if (notifications.any(
    (item) =>
        notification.messageId != null &&
        item.messageId == notification.messageId,
  )) {
    return;
  }
  await _saveNotifications([notification, ...notifications]);
}
