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

  Future<void> loadJournals(String topic) {
    return loadJournalsForSelection(label: topic);
  }

  Future<void> loadJournalsForSelection({
    required String label,
    String? domainId,
    String? fieldId,
  }) async {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) return;

    _isLoading = true;
    _error = null;
    _currentTopic = normalizedLabel;
    _journals = [];
    notifyListeners();

    try {
      final results = await Future.wait([
        _searchPage(
          normalizedLabel,
          domainId: domainId,
          fieldId: fieldId,
          page: 1,
        ),
        _searchPage(
          normalizedLabel,
          domainId: domainId,
          fieldId: fieldId,
          page: 2,
        ),
        _searchPage(
          normalizedLabel,
          domainId: domainId,
          fieldId: fieldId,
          page: 3,
        ),
        _searchPage(
          normalizedLabel,
          domainId: domainId,
          fieldId: fieldId,
          page: 4,
        ),
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

      _journals.sort(
        (a, b) => b.publicationCount.compareTo(a.publicationCount),
      );
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

  Future<List<Publication>> _searchPage(
    String topic, {
    String? domainId,
    String? fieldId,
    required int page,
  }) {
    if (fieldId != null && fieldId.isNotEmpty) {
      return _service.searchByDomainOrField(
        fieldId: fieldId,
        page: page,
        perPage: 25,
      );
    }
    if (domainId != null && domainId.isNotEmpty) {
      return _service.searchByDomainOrField(
        domainId: domainId,
        page: page,
        perPage: 25,
      );
    }
    return _service.searchPublicationsByPage(topic, page: page, perPage: 25);
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
