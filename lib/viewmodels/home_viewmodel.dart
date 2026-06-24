import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../models/domain.dart';
import '../services/openalex_service.dart';
import '../firebase/analytics_service.dart';

class HomeViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  List<Publication> _allPublications = [];
  List<String> _suggestedTopics = [];
  List<ResearchDomain> _domains = [];

  static const int _pageSize = 10;
  int _currentDisplayPage = 1;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _currentTopic = '';
  bool _isSearched = false;

  List<String> get suggestedTopics => _suggestedTopics;
  List<ResearchDomain> get domains => _domains;
  bool get isSearched => _isSearched;

  HomeViewModel() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _service.fetchSuggestedTopics(),
        _service.fetchDomains(),
      ]);
      _suggestedTopics = results[0] as List<String>;
      _domains = results[1] as List<ResearchDomain>;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> searchByField(ResearchField field) async {
    _isLoading = true;
    _error = null;
    _currentTopic = field.name;
    _allPublications = [];
    _currentDisplayPage = 1;
    _isSearched = true;
    notifyListeners();
    AnalyticsService.logSearchTopic(field.name);
    try {
      final results = await Future.wait([
        _service.searchByDomainOrField(fieldId: field.id, page: 1, perPage: 25),
        _service.searchByDomainOrField(fieldId: field.id, page: 2, perPage: 25),
      ]);
      final seenIds = <String>{};
      for (final page in results) {
        for (final pub in page) {
          if (seenIds.add(pub.id)) _allPublications.add(pub);
        }
      }
    } catch (e) {
      _error = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchByDomain(ResearchDomain domain) async {
    _isLoading = true;
    _error = null;
    _currentTopic = domain.name;
    _allPublications = [];
    _currentDisplayPage = 1;
    _isSearched = true;
    notifyListeners();
    AnalyticsService.logSearchTopic(domain.name);
    try {
      final results = await Future.wait([
        _service.searchByDomainOrField(domainId: domain.id, page: 1, perPage: 25),
        _service.searchByDomainOrField(domainId: domain.id, page: 2, perPage: 25),
      ]);
      final seenIds = <String>{};
      for (final page in results) {
        for (final pub in page) {
          if (seenIds.add(pub.id)) _allPublications.add(pub);
        }
      }
    } catch (e) {
      _error = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Publication> get allPublications => _allPublications;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get currentTopic => _currentTopic;
  int get currentDisplayPage => _currentDisplayPage;
  int get pageSize => _pageSize;

  List<Publication> get publications {
    final end = (_currentDisplayPage * _pageSize).clamp(0, _allPublications.length);
    return _allPublications.sublist(0, end);
  }

  int get totalPages => (_allPublications.length / _pageSize).ceil();
  bool get hasMore => _currentDisplayPage < totalPages;

  void clear() {
    _allPublications = [];
    _currentDisplayPage = 1;
    _error = null;
    _currentTopic = '';
    _isSearched = false;
    notifyListeners();
  }

  Future<void> search(String topic) async {
    if (topic.trim().isEmpty) return;
    _isLoading = true;
    _error = null;
    _currentTopic = topic.trim();
    _allPublications = [];
    _currentDisplayPage = 1;
    _isSearched = true;
    notifyListeners();
    AnalyticsService.logSearchTopic(_currentTopic);

    try {
      final results = await Future.wait([
        _service.searchPublicationsByPage(_currentTopic, page: 1, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: 2, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: 3, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: 4, perPage: 25),
      ]);
      final seenIds = <String>{};
      for (final page in results) {
        for (final pub in page) {
          if (seenIds.add(pub.id)) _allPublications.add(pub);
        }
      }
    } catch (_) {
      try {
        for (int page = 1; page <= 4; page++) {
          final result = await _service.searchPublicationsByPage(
            _currentTopic, page: page, perPage: 25,
          );
          final seenIds = _allPublications.map((p) => p.id).toSet();
          for (final pub in result) {
            if (!seenIds.contains(pub.id)) _allPublications.add(pub);
          }
        }
      } catch (e2) {
        if (_allPublications.isEmpty) {
          _error = 'Network error. Please try again.';
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadNextPage() {
    if (!hasMore) return;
    _currentDisplayPage++;
    notifyListeners();
  }

  void previousPage() {
    if (_currentDisplayPage <= 1) return;
    _currentDisplayPage--;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages) return;
    _currentDisplayPage = page;
    notifyListeners();
  }

  Future<void> loadMoreFromApi() async {
    if (_isLoadingMore || _currentTopic.isEmpty) return;
    _isLoadingMore = true;
    notifyListeners();

    final nextApiPage = (_allPublications.length / 25).floor() + 1;
    try {
      final results = await Future.wait([
        _service.searchPublicationsByPage(_currentTopic, page: nextApiPage, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: nextApiPage + 1, perPage: 25),
      ]);
      final seenIds = _allPublications.map((p) => p.id).toSet();
      for (final page in results) {
        for (final pub in page) {
          if (seenIds.add(pub.id)) _allPublications.add(pub);
        }
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Map<int, int> get publicationsByYear {
    final map = <int, int>{};
    for (final p in _allPublications) {
      if (p.year > 0) map[p.year] = (map[p.year] ?? 0) + 1;
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  List<Publication> get topInfluentialPapers {
    final sorted = List<Publication>.from(_allPublications)
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));
    return sorted.take(10).toList();
  }

  List<MapEntry<String, int>> get topJournals {
    final map = <String, int>{};
    for (final p in _allPublications) {
      final j = p.journalName;
      if (j != null && j.isNotEmpty) map[j] = (map[j] ?? 0) + 1;
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  List<MapEntry<String, int>> get topAuthors {
    final map = <String, int>{};
    for (final p in _allPublications) {
      for (final a in p.authors) {
        if (a.name != 'Unknown') map[a.name] = (map[a.name] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  int get totalPublications => _allPublications.length;

  double get averageCitationCount {
    if (_allPublications.isEmpty) return 0;
    final total = _allPublications.fold<int>(0, (sum, p) => sum + p.citationCount);
    return total / _allPublications.length;
  }

  int get mostActiveYear {
    if (publicationsByYear.isEmpty) return 0;
    return publicationsByYear.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String get topJournal => topJournals.isEmpty ? 'N/A' : topJournals.first.key;
  String get topAuthor => topAuthors.isEmpty ? 'N/A' : topAuthors.first.key;
  Publication? get mostInfluentialPaper =>
      topInfluentialPapers.isEmpty ? null : topInfluentialPapers.first;
}
