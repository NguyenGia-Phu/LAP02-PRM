import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend_analyzer/main.dart' as app;

const defaultTopic = 'machine learning';
const googleAccountText = 'ndanthanh161@gmail.com';
const postTestDisplayDelay = Duration(seconds: 3);

void patrolTestWithDelay(String description, PatrolTesterCallback callback) {
  patrolTest(description, ($) async {
    try {
      await callback($);
    } finally {
      await Future<void>.delayed(postTestDisplayDelay);
    }
  });
}

Future<void> launchApp(PatrolIntegrationTester $) async {
  await $.pumpWidgetAndSettle(const app.AppBootstrap());
  await dismissNotificationPermissionIfVisible($);
}

Future<void> dismissNotificationPermissionIfVisible(
  PatrolIntegrationTester $,
) async {
  if (await $.native.isPermissionDialogVisible(
    timeout: const Duration(seconds: 3),
  )) {
    await $.native.denyPermission();
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

Future<void> signInWithGoogle(PatrolIntegrationTester $) async {
  try {
    await $(
      'Journal Trend Analyzer',
    ).waitUntilVisible(timeout: const Duration(seconds: 5));
    return;
  } catch (_) {
    // Continue with the login screen flow.
  }

  await $('Sign in with Google').tap();
  await Future<void>.delayed(const Duration(seconds: 2));

  var accountSelected = false;
  for (final accountText in [googleAccountText]) {
    try {
      await $.native.tap(
        Selector(textContains: accountText),
        appId: 'com.google.android.gms',
        timeout: const Duration(seconds: 20),
      );
      accountSelected = true;
      break;
    } catch (_) {
      // The account picker may not appear if the session is already active.
    }
  }

  if (!accountSelected) {
    try {
      await $(
        'Journal Trend Analyzer',
      ).waitUntilVisible(timeout: const Duration(seconds: 10));
      return;
    } catch (_) {
      expect(accountSelected, isTrue);
    }
  }

  await $(
    'Journal Trend Analyzer',
  ).waitUntilVisible(timeout: const Duration(seconds: 45));
}

Future<void> launchAndSignIn(PatrolIntegrationTester $) async {
  await launchApp($);
  await signInWithGoogle($);
}

Future<void> searchTopic(PatrolIntegrationTester $, String topic) async {
  await $(TextField).enterText(topic);
  await $('Search').tap();
  await $(
    find.textContaining('Publications ('),
  ).waitUntilVisible(timeout: const Duration(seconds: 120));
}

Future<void> analyzeCurrentTab(PatrolIntegrationTester $, String topic) async {
  await $(TextField).enterText(topic);
  await $('Analyze').tap();
}

Future<void> openJournalsTab(PatrolIntegrationTester $) async {
  await $('Journals').tap();
  await $(
    'Journal Contributor Analysis',
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
}

Future<void> openKeywordsTab(PatrolIntegrationTester $) async {
  await $('Keywords').tap();
  await $(
    'Keyword Trend Analysis',
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
}

Future<void> openProfileTab(PatrolIntegrationTester $) async {
  await $('Profile').tap();
  await $(
    'Researcher Profile',
  ).waitUntilVisible(timeout: const Duration(seconds: 30));
}
