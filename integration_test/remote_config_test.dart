import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC10: Retrieve Remote Config values -> verify they are displayed in Profile screen
  patrolTest(
    'TC10: Remote Config - verify config values are displayed',
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

      // Step 3: Verify Remote Config section is visible
      expect($('Remote Config Values'), findsOneWidget);

      // Step 4: Verify the two config parameters are displayed
      expect($('Max Journals Displayed'), findsOneWidget);
      expect($('Max Keywords Displayed'), findsOneWidget);

      // Step 5: Tap Refresh Config button (IconButton with refresh icon)
      await $(find.byTooltip('Fetch Config')).tap();
      await $.pumpAndSettle();

      // Step 6: Verify refresh success SnackBar appears
      expect($('Remote config refreshed!'), findsOneWidget);
    },
  );
}
