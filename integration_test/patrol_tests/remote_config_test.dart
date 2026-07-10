import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTest(
    'TC10: Remote Config retrieves and displays configuration values',
    ($) async {
      await launchAndSignIn($);
      await openProfileTab($);

      await $('Remote Config Values').scrollTo();
      expect($('Remote Config Values'), findsOneWidget);
      expect($('Max Journals Displayed'), findsOneWidget);
      expect($('Max Keywords Displayed'), findsOneWidget);

      await $(find.byTooltip('Fetch Config')).tap();
      await $(
        'Remote config refreshed!',
      ).waitUntilVisible(timeout: const Duration(seconds: 30));

      await pauseForEvidence();
    },
  );
}
