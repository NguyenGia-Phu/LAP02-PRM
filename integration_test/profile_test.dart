import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC8: Navigate to Profile tab -> verify user info is displayed
  patrolTest(
    'TC8: Profile tab - verify user information is displayed',
    ($) async {
      await $.pumpWidgetAndSettle(
        app.JournalTrendApp(
          fcmService: FcmService(),
          remoteConfigService: RemoteConfigService(),
        ),
      );

      // Step 1: Sign in with Google
      await $('Sign in with Google').tap();
      await $.pumpAndSettle();

      // Step 2: Navigate to Profile tab
      await $('Profile').tap();
      await $.pumpAndSettle();

      // Step 3: Verify Profile screen app bar is shown
      expect($('Researcher Profile'), findsOneWidget);

      // Step 4: Verify user info card is present (sign out button visible)
      expect($('Sign Out'), findsOneWidget);

      // Step 5: Verify Notification Center section is present
      expect($('Notification Center'), findsOneWidget);

      // Step 6: Verify empty state notification message (no notifications yet)
      expect($('No notifications received yet'), findsOneWidget);
    },
  );
}
