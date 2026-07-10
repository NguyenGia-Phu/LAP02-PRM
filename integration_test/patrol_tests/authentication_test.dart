import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTest('TC1: Google Sign-In navigates to Home screen', ($) async {
    await launchAndSignIn($);

    expect($('Journal Trend Analyzer'), findsOneWidget);
    expect($('Home'), findsOneWidget);
    expect($('Journals'), findsOneWidget);
    expect($('Keywords'), findsOneWidget);
    expect($('Profile'), findsOneWidget);
  });

  patrolTest('TC11: Logout redirects to Login screen', ($) async {
    await launchAndSignIn($);
    await openProfileTab($);

    await $('Sign Out').scrollTo();
    await $('Sign Out').tap();

    await $(
      'TrendAnalyzer',
    ).waitUntilVisible(timeout: const Duration(seconds: 30));
    expect($('Sign in with Google'), findsOneWidget);
  });
}
