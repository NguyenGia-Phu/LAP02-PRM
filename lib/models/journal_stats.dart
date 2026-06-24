import 'publication.dart';

class JournalStats {
  final String name;
  final int publicationCount;
  final int totalCitations;
  final double avgCitations;
  final List<Publication> publications;

  JournalStats({
    required this.name,
    required this.publicationCount,
    required this.totalCitations,
    required this.avgCitations,
    required this.publications,
  });
}
