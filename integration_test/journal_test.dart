import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTestWithDelay(
    'TC4: Journals Navigation displays journal statistics and list',
    ($) async {
      await launchAndSignIn($);
      await openJournalsTab($);
      await analyzeCurrentTab($, defaultTopic);

      await $(
        'Latest Journals',
      ).waitUntilVisible(timeout: const Duration(seconds: 120));

      expect($('Journal Contributor Analysis'), findsOneWidget);
      expect(find.textContaining('Analysis for:'), findsNothing);
      expect(find.text('Distribution of Top Journals'), findsNothing);
      expect($('Latest Journals'), findsOneWidget);
    },
  );

  patrolTestWithDelay(
    'TC5: Journal Details displays selected journal information',
    ($) async {
      await launchAndSignIn($);
      await openJournalsTab($);
      await analyzeCurrentTab($, defaultTopic);

      await $(
        'Latest Journals',
      ).waitUntilVisible(timeout: const Duration(seconds: 120));
      await $(find.byType(ListTile)).at(0).tap();
      await $(
        'Journal Detail',
      ).waitUntilVisible(timeout: const Duration(seconds: 30));

      expect($('Journal Detail'), findsOneWidget);
      expect(find.textContaining('Publications'), findsWidgets);
      expect(find.textContaining('Total Citations'), findsWidgets);
    },
  );
}
