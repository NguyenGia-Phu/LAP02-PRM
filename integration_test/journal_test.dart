import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC4: Navigate to Journals tab -> verify stats and journal list are displayed
  patrolTest(
    'TC4: Journals tab - verify journal stats and list are displayed',
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

      // Step 2: Navigate to Journals tab
      await $('Journals').tap();
      await $.pumpAndSettle();

      // Step 3: Verify Journals screen is shown
      expect($('Journal Contributor Analysis'), findsOneWidget);

      // Step 4: Enter a topic and tap Analyze
      await $(TextField).enterText('blockchain');
      await $('Analyze').tap();
      await $.pumpAndSettle();

      // Step 5: Verify results section appears with analysis header
      expect(find.textContaining('Analysis for:'), findsOneWidget);
    },
  );

  // TC5: Open journal -> verify journal detail screen is displayed
  patrolTest(
    'TC5: Open journal - verify journal detail screen is displayed',
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

      // Step 2: Navigate to Journals tab and search
      await $('Journals').tap();
      await $.pumpAndSettle();
      await $(TextField).enterText('deep learning');
      await $('Analyze').tap();
      await $.pumpAndSettle();

      // Step 3: Verify results appear
      expect(find.textContaining('Analysis for:'), findsOneWidget);

      // Step 4: Tap the first journal item in the ranked list
      await $(find.byType(ListTile)).at(0).tap();
      await $.pumpAndSettle();

      // Step 5: Verify Journal Detail screen is shown
      expect($('Journal Detail'), findsOneWidget);
      expect($('Total Publications'), findsWidgets);
      expect($('Total Citations'), findsWidgets);
    },
  );
}
