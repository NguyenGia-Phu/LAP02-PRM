import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint(
    'Received background message: ${message.notification?.title ?? message.messageId}',
  );
}

class FcmNotification {
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
      _addNotification(initialMessage);
    }

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
    final data = message.data;
    _notifications.insert(
      0,
      FcmNotification(
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: data['type'],
        topic: data['topic'],
        publicationTitle: data['publicationTitle'],
        publicationId: data['publicationId'],
        citations: FcmNotification._parseInt(data['citations']),
        publicationYear: FcmNotification._parseInt(data['publicationYear']),
      ),
    );
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
