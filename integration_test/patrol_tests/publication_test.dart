import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/widgets/publication_card.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTestWithDelay('TC2: Topic Search displays publication results', (
    $,
  ) async {
    await launchAndSignIn($);
    await searchTopic($, defaultTopic);

    expect(find.textContaining('Publications ('), findsOneWidget);
    expect(find.byType(PublicationCard), findsWidgets);
  });

  patrolTestWithDelay(
    'TC3: Publication Details displays publication information',
    ($) async {
      await launchAndSignIn($);
      await searchTopic($, defaultTopic);

      await $(find.byType(PublicationCard)).at(0).tap();
      await $(
        'Publication Detail',
      ).waitUntilVisible(timeout: const Duration(seconds: 30));

      expect($('Publication Detail'), findsOneWidget);
      if (find.text('Remove Bookmark').evaluate().isNotEmpty) {
        await $('Remove Bookmark').tap();
      }
      expect($('Save Bookmark'), findsOneWidget);
      await $('Save Bookmark').tap();
      expect($('Remove Bookmark'), findsOneWidget);

      expect(find.textContaining('Year:'), findsWidgets);
      expect(find.textContaining('Citations:'), findsWidgets);
      expect(find.textContaining('Journal:'), findsWidgets);
    },
  );
}
