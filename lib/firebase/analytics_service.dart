import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track user login
  static Future<void> logLogin() async {
    try {
      await _analytics.logEvent(name: 'login');
      debugPrint("Analytics logged: login");
    } catch (e) {
      debugPrint("Analytics login error: $e");
    }
  }

  // Track topic search
  static Future<void> logSearchTopic(String keyword) async {
    try {
      await _analytics.logEvent(
        name: 'search_topic',
        parameters: {'keyword': keyword},
      );
      debugPrint("Analytics logged: search_topic ($keyword)");
    } catch (e) {
      debugPrint("Analytics search_topic error: $e");
    }
  }

  // Track publication view
  static Future<void> logViewPublication(String title, int year) async {
    try {
      await _analytics.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': title,
          'publication_year': year,
        },
      );
      debugPrint("Analytics logged: view_publication ($title, $year)");
    } catch (e) {
      debugPrint("Analytics view_publication error: $e");
    }
  }

  // Track journal view
  static Future<void> logViewJournal(String journalName) async {
    try {
      await _analytics.logEvent(
        name: 'view_journal',
        parameters: {'journal_name': journalName},
      );
      debugPrint("Analytics logged: view_journal ($journalName)");
    } catch (e) {
      debugPrint("Analytics view_journal error: $e");
    }
  }

  // Track keyword view
  static Future<void> logViewKeyword(String keyword) async {
    try {
      await _analytics.logEvent(
        name: 'view_keyword',
        parameters: {'keyword': keyword},
      );
      debugPrint("Analytics logged: view_keyword ($keyword)");
    } catch (e) {
      debugPrint("Analytics view_keyword error: $e");
    }
  }

  // Track PDF export
  static Future<void> logExportPdf(String topic) async {
    try {
      await _analytics.logEvent(
        name: 'export_pdf',
        parameters: {'topic': topic},
      );
      debugPrint("Analytics logged: export_pdf ($topic)");
    } catch (e) {
      debugPrint("Analytics export_pdf error: $e");
    }
  }

  // Track user logout
  static Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      debugPrint("Analytics logged: logout");
    } catch (e) {
      debugPrint("Analytics logout error: $e");
    }
  }
}
