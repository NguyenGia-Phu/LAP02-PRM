import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC6: Navigate to Keywords tab -> verify keyword stats and list are displayed
  patrolTest(
    'TC6: Keywords tab - verify keyword stats and list are displayed',
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

      // Step 2: Navigate to Keywords tab
      await $('Keywords').tap();
      await $.pumpAndSettle();

      // Step 3: Verify Keywords screen is shown
      expect($('Keyword Trend Analysis'), findsOneWidget);

      // Step 4: Enter a topic and tap Analyze
      await $(TextField).enterText('cloud computing');
      await $('Analyze').tap();
      await $.pumpAndSettle();

      // Step 5: Verify results appear
      expect(find.textContaining('Analysis for:'), findsOneWidget);
    },
  );

  // TC7: Open keyword -> verify keyword analysis detail is displayed
  patrolTest(
    'TC7: Open keyword - verify keyword analysis detail is displayed',
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

      // Step 2: Navigate to Keywords tab and search
      await $('Keywords').tap();
      await $.pumpAndSettle();
      await $(TextField).enterText('neural networks');
      await $('Analyze').tap();
      await $.pumpAndSettle();

      // Step 3: Verify results appear
      expect(find.textContaining('Analysis for:'), findsOneWidget);

      // Step 4: Tap the first keyword item
      await $(find.byType(ListTile)).at(0).tap();
      await $.pumpAndSettle();

      // Step 5: Verify Keyword Detail screen is shown with trend info
      expect($('Keyword Detail'), findsOneWidget);
      expect($('Publication Trend'), findsWidgets);
      expect($('Related Journals'), findsWidgets);
    },
  );
}
