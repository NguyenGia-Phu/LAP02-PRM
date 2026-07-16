import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'patrol_test_helpers.dart';

void main() {
  patrolTestWithDelay('TC8: Profile Navigation displays user profile information', (
    $,
  ) async {
    await launchAndSignIn($);
    await openProfileTab($);

    expect($('Researcher Profile'), findsOneWidget);
    expect($('Sign Out'), findsOneWidget);
    expect($('Notification Center'), findsOneWidget);
  });
}
