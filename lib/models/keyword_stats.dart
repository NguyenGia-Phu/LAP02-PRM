import 'publication.dart';

class KeywordStats {
  final String keyword;
  final int frequency;
  final Map<int, int> trendByYear;
  final List<String> relatedJournals;
  final List<Publication> publications;
  final Map<String, int> authorPublicationCounts;

  KeywordStats({
    required this.keyword,
    required this.frequency,
    required this.trendByYear,
    required this.relatedJournals,
    required this.publications,
    required this.authorPublicationCounts,
  });
}
