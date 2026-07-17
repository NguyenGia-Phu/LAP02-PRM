import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:journal_trend_analyzer/screens/login_screen.dart';
import 'package:journal_trend_analyzer/screens/home/home_screen.dart';
import 'package:journal_trend_analyzer/screens/journals/journals_screen.dart';
import 'package:journal_trend_analyzer/screens/keywords/keywords_screen.dart';
import 'package:journal_trend_analyzer/screens/profile/profile_tab_screen.dart';
import 'package:journal_trend_analyzer/viewmodels/auth_viewmodel.dart';
import 'package:journal_trend_analyzer/viewmodels/home_viewmodel.dart';
import 'package:journal_trend_analyzer/viewmodels/journals_viewmodel.dart';
import 'package:journal_trend_analyzer/viewmodels/keywords_viewmodel.dart';
import 'package:journal_trend_analyzer/firebase/fcm_service.dart';
import 'package:journal_trend_analyzer/firebase/remote_config_service.dart';
import 'package:journal_trend_analyzer/models/domain.dart';
import 'package:journal_trend_analyzer/models/publication.dart';
import 'package:journal_trend_analyzer/models/journal_stats.dart';
import 'package:journal_trend_analyzer/models/keyword_stats.dart';

// Mock AuthViewModel
class MockAuthViewModel extends ChangeNotifier implements AuthViewModel {
  @override
  User? get user => null;
  @override
  bool get isAuthenticated => false;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  Future<bool> signInWithGoogle() async => true;
  @override
  Future<void> signOut() async {}
}

// Mock HomeViewModel
class MockHomeViewModel extends ChangeNotifier implements HomeViewModel {
  @override
  List<String> get suggestedTopics => ['AI', 'Data Science'];
  @override
  List<ResearchDomain> get domains => [];
  @override
  bool get isSearched => false;
  @override
  bool get isLoading => false;
  @override
  bool get isLoadingMore => false;
  @override
  String? get error => null;
  @override
  String get currentTopic => '';
  @override
  int get currentDisplayPage => 1;
  @override
  int get pageSize => 10;
  @override
  List<Publication> get publications => [];
  @override
  List<Publication> get allPublications => [];
  @override
  int get totalPages => 0;
  @override
  bool get hasMore => false;
  @override
  void clear() {}
  @override
  Future<void> search(String topic) async {}
  @override
  Future<void> searchByField(field) async {}
  @override
  Future<void> searchByDomain(domain) async {}
  @override
  void loadNextPage() {}
  @override
  void previousPage() {}
  @override
  void goToPage(int page) {}
  @override
  Future<void> loadMoreFromApi() async {}
  @override
  Map<int, int> get publicationsByYear => {};
  @override
  List<Publication> get topInfluentialPapers => [];
  @override
  List<MapEntry<String, int>> get topJournals => [];
  @override
  List<MapEntry<String, int>> get topAuthors => [];
  @override
  int get totalPublications => 0;
  @override
  double get averageCitationCount => 0.0;
  @override
  int get mostActiveYear => 0;
  @override
  String get topJournal => 'N/A';
  @override
  String get topAuthor => 'N/A';
  @override
  Publication? get mostInfluentialPaper => null;
}

// Mock JournalsViewModel
class MockJournalsViewModel extends ChangeNotifier
    implements JournalsViewModel {
  final List<JournalStats> _journals;

  MockJournalsViewModel([this._journals = const []]);

  @override
  List<JournalStats> get journals => _journals;
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  String get currentTopic => _journals.isEmpty ? '' : 'manual search';
  @override
  Future<void> loadJournals(String topic) async {}
  @override
  void clear() {}
}

// Mock KeywordsViewModel
class MockKeywordsViewModel extends ChangeNotifier
    implements KeywordsViewModel {
  @override
  List<KeywordStats> get keywords => [];
  @override
  List<KeywordStats> get trendingKeywords => [];
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  String get currentTopic => '';
  @override
  Future<void> loadKeywords(String topic) async {}
  @override
  void clear() {}
}

// Mock FcmService
class MockFcmService extends ChangeNotifier implements FcmService {
  final List<FcmNotification> _notifications = [
    FcmNotification(
      title: 'New trending research topic',
      body: 'A publication is trending in machine learning.',
      timestamp: DateTime(2026, 7, 16, 10, 30),
      type: 'trending_topic',
      topic: 'machine learning',
      publicationTitle: 'A publication',
      publicationId: 'https://openalex.org/W123',
      citations: 42,
      publicationYear: 2026,
    ),
  ];

  @override
  List<FcmNotification> get notifications => _notifications;
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> getToken() async => 'mock-token';
  @override
  Future<void> setupMessageHandlers() async {}
  @override
  Future<void> clearNotifications() async {
    _notifications.clear();
    notifyListeners();
  }
}

// Mock RemoteConfigService
class MockRemoteConfigService implements RemoteConfigService {
  @override
  Future<void> initialize() async {}
  @override
  int get maxJournalsDisplayed => 10;
  @override
  int get maxKeywordsDisplayed => 20;
  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('LoginScreen renders premium widgets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthViewModel>.value(
          value: MockAuthViewModel(),
          child: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('TrendAnalyzer'), findsOneWidget);
    expect(find.text('Firebase-Powered Journal Insights'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('HomeScreen renders initial search bar and state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<HomeViewModel>.value(
          value: MockHomeViewModel(),
          child: const HomeScreen(),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Artificial Intelligence'), findsOneWidget);
    expect(find.text('Data Science'), findsOneWidget);
  });

  testWidgets('JournalsScreen renders inputs and empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<JournalsViewModel>.value(
              value: MockJournalsViewModel(),
            ),
            Provider<RemoteConfigService>.value(
              value: MockRemoteConfigService(),
            ),
          ],
          child: const JournalsScreen(),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
    final journalSearch = tester.widget<TextField>(find.byType(TextField));
    expect(journalSearch.controller?.text, isEmpty);

    expect(
      find.text('Enter a topic above to analyze publishing journals.'),
      findsOneWidget,
    );
  });

  testWidgets('JournalsScreen shows only journals ordered by latest year', (
    WidgetTester tester,
  ) async {
    final publications = [
      Publication(
        id: 'W-new',
        title: 'New publication',
        year: 2026,
        citationCount: 10,
        authors: const [],
        keywords: const [],
      ),
      Publication(
        id: 'W-old',
        title: 'Old publication',
        year: 2023,
        citationCount: 5,
        authors: const [],
        keywords: const [],
      ),
    ];
    final journalStats = JournalStats(
      name: 'Test Journal',
      publicationCount: publications.length,
      totalCitations: 15,
      avgCitations: 7.5,
      publications: publications,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<JournalsViewModel>.value(
              value: MockJournalsViewModel([journalStats]),
            ),
            Provider<RemoteConfigService>.value(
              value: MockRemoteConfigService(),
            ),
          ],
          child: const JournalsScreen(),
        ),
      ),
    );

    expect(find.text('Latest Journals'), findsOneWidget);
    expect(find.text('Latest publication: 2026'), findsOneWidget);
    expect(find.textContaining('Analysis for:'), findsNothing);
    expect(find.text('Unique Journals'), findsNothing);
    expect(find.text('Avg Citation Rate'), findsNothing);
    expect(find.text('Distribution of Top Journals'), findsNothing);
  });

  testWidgets('KeywordsScreen renders search bar and empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<KeywordsViewModel>.value(
              value: MockKeywordsViewModel(),
            ),
            Provider<RemoteConfigService>.value(
              value: MockRemoteConfigService(),
            ),
          ],
          child: const KeywordsScreen(),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
    final keywordSearch = tester.widget<TextField>(find.byType(TextField));
    expect(keywordSearch.controller?.text, isEmpty);

    expect(
      find.text('Enter a topic above to analyze research keywords.'),
      findsOneWidget,
    );
  });

  testWidgets('ProfileTabScreen renders profile sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(
              value: MockAuthViewModel(),
            ),
            ChangeNotifierProvider<FcmService>.value(value: MockFcmService()),
            Provider<RemoteConfigService>.value(
              value: MockRemoteConfigService(),
            ),
          ],
          child: const ProfileTabScreen(),
        ),
      ),
    );

    expect(find.text('Researcher Profile'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.text('No bookmarks yet.'), findsOneWidget);
    expect(find.text('Notification Center'), findsOneWidget);
    expect(find.text('machine learning'), findsOneWidget);
    expect(find.text('Tap to explore related publications'), findsOneWidget);
    expect(find.text('Export Trend Report'), findsOneWidget);
    expect(find.text('Remote Config Values'), findsOneWidget);
    expect(find.text('Crashlytics Diagnostics'), findsOneWidget);
  });
}
