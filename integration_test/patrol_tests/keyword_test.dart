import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTest('TC6: Keywords Navigation displays keyword statistics and list', (
    $,
  ) async {
    await launchAndSignIn($);
    await openKeywordsTab($);
    await analyzeCurrentTab($, defaultTopic);

    await $(
      'Keyword Frequencies',
    ).waitUntilVisible(timeout: const Duration(seconds: 120));

    expect($('Keyword Trend Analysis'), findsOneWidget);
    expect($('Top 5 Most Frequent Keywords'), findsOneWidget);
    expect($('Trending Keywords'), findsOneWidget);
    expect($('Keyword Frequencies'), findsOneWidget);
  });

  patrolTest('TC7: Keyword Details displays selected keyword analysis', (
    $,
  ) async {
    await launchAndSignIn($);
    await openKeywordsTab($);
    await analyzeCurrentTab($, defaultTopic);

    await $(
      'Keyword Frequencies',
    ).waitUntilVisible(timeout: const Duration(seconds: 120));
    await $(find.byType(ListTile)).at(0).tap();
    await $(
      'Keyword Detail',
    ).waitUntilVisible(timeout: const Duration(seconds: 30));

    expect($('Keyword Detail'), findsOneWidget);
    expect($('Publication Trend Over Time'), findsOneWidget);
    expect($('Top Contributing Authors'), findsOneWidget);
  });
}
