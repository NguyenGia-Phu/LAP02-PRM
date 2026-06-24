import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC1: Launch app -> verify Login screen is shown
  patrolTest(
    'TC1: Launch app - verify Login screen is displayed',
    ($) async {
      await $.pumpWidgetAndSettle(
        app.JournalTrendApp(
          fcmService: FcmService(),
          remoteConfigService: RemoteConfigService(),
        ),
      );

      // Verify the app title is visible on the Login screen
      expect($('TrendAnalyzer'), findsOneWidget);

      // Verify the Google Sign-In button is present
      expect($('Sign in with Google'), findsOneWidget);

      // Verify subtitle text
      expect($('Firebase-Powered Journal Insights'), findsOneWidget);
    },
  );

  // TC11: After login, sign out -> verify Login screen is shown again
  patrolTest(
    'TC11: Sign out - verify Login screen is shown again',
    ($) async {
      await $.pumpWidgetAndSettle(
        app.JournalTrendApp(
          fcmService: FcmService(),
          remoteConfigService: RemoteConfigService(),
        ),
      );

      // Step 1: Sign in with Google (requires manual interaction on device)
      await $('Sign in with Google').tap();
      await $.pumpAndSettle();

      // Step 2: After successful login, navigate to Profile tab
      await $('Profile').tap();
      await $.pumpAndSettle();

      // Verify Profile screen is shown
      expect($('Researcher Profile'), findsOneWidget);

      // Step 3: Tap Sign Out
      await $('Sign Out').tap();
      await $.pumpAndSettle();

      // Step 4: Verify Login screen is shown again
      expect($('TrendAnalyzer'), findsOneWidget);
      expect($('Sign in with Google'), findsOneWidget);
    },
  );
}
