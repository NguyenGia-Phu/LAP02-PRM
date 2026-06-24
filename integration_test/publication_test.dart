import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC2: Search topic -> verify results are displayed
  patrolTest(
    'TC2: Search topic - verify publication results are displayed',
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

      // Step 2: Verify Home screen is shown
      expect($('Journal Trend Analyzer'), findsOneWidget);

      // Step 3: Enter search topic
      await $(TextField).enterText('machine learning');

      // Step 4: Tap Search button
      await $('Search').tap();
      await $.pumpAndSettle();

      // Step 5: Verify search results appear (Dashboard header)
      expect(find.textContaining('Dashboard:'), findsOneWidget);

      // Step 6: Verify trend chart section is shown
      expect($('Publications Per Year'), findsOneWidget);
    },
  );

  // TC3: Open publication -> verify detail screen is displayed
  patrolTest(
    'TC3: Open publication - verify publication details are displayed',
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

      // Step 2: Search for a topic
      await $(TextField).enterText('artificial intelligence');
      await $('Search').tap();
      await $.pumpAndSettle();

      // Step 3: Verify results are shown before tapping
      expect(find.textContaining('Dashboard:'), findsOneWidget);

      // Step 4: Tap the first publication card in the list
      await $(find.byType(Card)).at(0).tap();
      await $.pumpAndSettle();

      // Step 5: Verify publication detail screen elements are shown
      expect($('Abstract'), findsWidgets);
      expect($('Citations'), findsWidgets);
    },
  );
}
