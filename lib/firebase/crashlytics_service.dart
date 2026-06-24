import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  static Future<void> logHandledException(dynamic error, StackTrace stack) async {
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
  }

  static Future<void> testCrash() async {
    FirebaseCrashlytics.instance.crash();
  }

  static Future<void> setUserIdentifier(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }
}
