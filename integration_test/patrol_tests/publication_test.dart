import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTest('TC2: Topic Search displays publication results', ($) async {
    await launchAndSignIn($);
    await searchTopic($, defaultTopic);

    expect(find.textContaining('Dashboard:'), findsOneWidget);
    expect($('Publications Per Year'), findsOneWidget);
    expect(find.textContaining('Total Publications'), findsWidgets);
  });

  patrolTest('TC3: Publication Details displays publication information', (
    $,
  ) async {
    await launchAndSignIn($);
    await searchTopic($, defaultTopic);

    await $('Most Influential Paper').scrollTo();
    await $('Most Influential Paper').tap();
    await $(
      'Publication Detail',
    ).waitUntilVisible(timeout: const Duration(seconds: 30));

    expect($('Publication Detail'), findsOneWidget);
    expect(find.textContaining('Year:'), findsWidgets);
    expect(find.textContaining('Citations:'), findsWidgets);
    expect(find.textContaining('Journal:'), findsWidgets);
  });
}
