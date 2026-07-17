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
    final normalizedLabel = topic.trim();
    if (normalizedLabel.isEmpty) return;

    _isLoading = true;
    _error = null;
    _currentTopic = normalizedLabel;
    _journals = [];
    notifyListeners();

    try {
      final results = await Future.wait([
        _searchPage(normalizedLabel, page: 1),
        _searchPage(normalizedLabel, page: 2),
        _searchPage(normalizedLabel, page: 3),
        _searchPage(normalizedLabel, page: 4),
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
        list.sort((a, b) => b.year.compareTo(a.year));
        final totalCitations = list.fold<int>(
          0,
          (sum, p) => sum + p.citationCount,
        );
        final avgCitations = list.isEmpty ? 0.0 : totalCitations / list.length;
        return JournalStats(
          name: name,
          publicationCount: list.length,
          totalCitations: totalCitations,
          avgCitations: avgCitations,
          publications: list,
        );
      }).toList();

      _journals.sort(compareJournalsByLatestPublication);
    } catch (e, st) {
      debugPrint('[JournalsViewModel] loadJournals failed: $e');
      debugPrintStack(
        stackTrace: st,
        label: '[JournalsViewModel] loadJournals stack',
      );
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Publication>> _searchPage(String topic, {required int page}) {
    return _service.searchPublicationsByPage(
      topic,
      page: page,
      perPage: 25,
      sort: 'publication_date:desc',
    );
  }

  void clear() {
    _journals = [];
    _error = null;
    _currentTopic = '';
    notifyListeners();
  }
}
