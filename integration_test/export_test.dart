import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTestWithDelay('TC9: PDF Export uploads report and displays download URL', (
    $,
  ) async {
    await launchAndSignIn($);
    await openProfileTab($);

    await $('Export Trend Report').scrollTo();
    expect($('Export Trend Report'), findsOneWidget);

    await $(TextField).enterText(defaultTopic);
    await $('Export PDF Report').tap();

    await $(
      'Export Link Available:',
    ).waitUntilVisible(timeout: const Duration(seconds: 180));
    expect($('Export Link Available:'), findsOneWidget);
  });
}
