import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

void main() {
  // TC9: Generate PDF report -> upload to Firebase Storage -> verify URL is displayed
  patrolTest(
    'TC9: Export PDF report - verify upload and download URL are shown',
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

      // Step 3: Verify Export section is visible
      expect($('Export Trend Report'), findsOneWidget);

      // Step 4: Enter a topic in the export text field
      await $(TextField).enterText('IoT');

      // Step 5: Tap the Export PDF Report button
      await $('Export PDF Report').tap();

      // Step 6: Wait for fetch + PDF generation + Storage upload to complete
      await $.pumpAndSettle();

      // Step 7: Verify success SnackBar message appears
      expect($('Report generated and uploaded successfully!'), findsOneWidget);

      // Step 8: Verify download link section appears
      expect($('Export Link Available:'), findsOneWidget);
    },
  );
}
