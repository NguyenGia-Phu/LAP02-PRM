import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../models/keyword_stats.dart';
import '../services/openalex_service.dart';

class KeywordsViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  List<KeywordStats> _keywords = [];
  List<KeywordStats> _trendingKeywords = [];
  bool _isLoading = false;
  String? _error;
  String _currentTopic = '';

  List<KeywordStats> get keywords => _keywords;
  List<KeywordStats> get trendingKeywords => _trendingKeywords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentTopic => _currentTopic;

  Future<void> loadKeywords(String topic) async {
    if (topic.trim().isEmpty) return;
    _isLoading = true;
    _error = null;
    _currentTopic = topic.trim();
    _keywords = [];
    _trendingKeywords = [];
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.searchPublicationsByPage(_currentTopic, page: 1, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: 2, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: 3, perPage: 25),
        _service.searchPublicationsByPage(_currentTopic, page: 4, perPage: 25),
      ]);

      final allPubs = <Publication>[];
      final seenIds = <String>{};
      for (final page in results) {
        for (final pub in page) {
          if (seenIds.add(pub.id)) allPubs.add(pub);
        }
      }

      // Group publications by keyword
      final keywordMap = <String, List<Publication>>{};
      for (final pub in allPubs) {
        final extracted = _service.getKeywordsFromPublications([pub]);
        for (final rawKey in extracted) {
          final key = _toTitleCase(rawKey);
          if (key.isNotEmpty) {
            keywordMap.putIfAbsent(key, () => []).add(pub);
          }
        }
      }

      // Compute statistics for each keyword
      final tempKeywords = <KeywordStats>[];
      for (final entry in keywordMap.entries) {
        final word = entry.key;
        final list = entry.value;

        // trendByYear
        final trend = <int, int>{};
        for (final p in list) {
          trend[p.year] = (trend[p.year] ?? 0) + 1;
        }

        // relatedJournals
        final journals = list
            .map((p) => p.journalName)
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        // authorPublicationCounts
        final authorCounts = <String, int>{};
        for (final p in list) {
          for (final a in p.authors) {
            if (a.name.isNotEmpty) {
              authorCounts[a.name] = (authorCounts[a.name] ?? 0) + 1;
            }
          }
        }

        tempKeywords.add(
          KeywordStats(
            keyword: word,
            frequency: list.length,
            trendByYear: trend,
            relatedJournals: journals,
            publications: list,
            authorPublicationCounts: authorCounts,
          ),
        );
      }

      // Sort by frequency descending for overall list
      tempKeywords.sort((a, b) => b.frequency.compareTo(a.frequency));
      _keywords = tempKeywords;

      // Identify trending keywords based on recent growth (last 2 years vs previous 2 years)
      int maxYear = DateTime.now().year;
      if (allPubs.isNotEmpty) {
        maxYear = allPubs.map((p) => p.year).reduce((a, b) => a > b ? a : b);
      }

      final tempTrending = List<KeywordStats>.from(tempKeywords);
      tempTrending.sort((a, b) {
        final recentA = (a.trendByYear[maxYear] ?? 0) + (a.trendByYear[maxYear - 1] ?? 0);
        final pastA = (a.trendByYear[maxYear - 2] ?? 0) + (a.trendByYear[maxYear - 3] ?? 0);
        final scoreA = recentA - pastA;

        final recentB = (b.trendByYear[maxYear] ?? 0) + (b.trendByYear[maxYear - 1] ?? 0);
        final pastB = (b.trendByYear[maxYear - 2] ?? 0) + (b.trendByYear[maxYear - 3] ?? 0);
        final scoreB = recentB - pastB;

        // If growth score is equal, sort by overall frequency
        if (scoreB == scoreA) {
          return b.frequency.compareTo(a.frequency);
        }
        return scoreB.compareTo(scoreA);
      });

      _trendingKeywords = tempTrending;
    } catch (e) {
      _error = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void clear() {
    _keywords = [];
    _trendingKeywords = [];
    _error = null;
    _currentTopic = '';
    notifyListeners();
  }
}
