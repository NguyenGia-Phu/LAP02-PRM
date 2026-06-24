import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../models/journal_stats.dart';
import '../services/openalex_service.dart';

class JournalsViewModel extends ChangeNotifier {
  final OpenAlexService _service = OpenAlexService();

  List<JournalStats> _journals = [];
  bool _isLoading = false;
  String? _error;
  String _currentTopic = '';

  List<JournalStats> get journals => _journals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentTopic => _currentTopic;

  Future<void> loadJournals(String topic) async {
    if (topic.trim().isEmpty) return;
    _isLoading = true;
    _error = null;
    _currentTopic = topic.trim();
    _journals = [];
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

      final groups = <String, List<Publication>>{};
      for (final pub in allPubs) {
        final journal = pub.journalName;
        if (journal != null && journal.isNotEmpty) {
          groups.putIfAbsent(journal, () => []).add(pub);
        }
      }

      _journals = groups.entries.map((entry) {
        final name = entry.key;
        final list = entry.value;
        final totalCitations = list.fold<int>(0, (sum, p) => sum + p.citationCount);
        final avgCitations = list.isEmpty ? 0.0 : totalCitations / list.length;
        return JournalStats(
          name: name,
          publicationCount: list.length,
          totalCitations: totalCitations,
          avgCitations: avgCitations,
          publications: list,
        );
      }).toList();

      _journals.sort((a, b) => b.publicationCount.compareTo(a.publicationCount));
    } catch (e) {
      _error = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void sortByPublicationCount() {
    _journals.sort((a, b) => b.publicationCount.compareTo(a.publicationCount));
    notifyListeners();
  }

  void sortByTotalCitations() {
    _journals.sort((a, b) => b.totalCitations.compareTo(a.totalCitations));
    notifyListeners();
  }

  void sortByAvgCitations() {
    _journals.sort((a, b) => b.avgCitations.compareTo(a.avgCitations));
    notifyListeners();
  }

  void clear() {
    _journals = [];
    _error = null;
    _currentTopic = '';
    notifyListeners();
  }
}
