import 'publication.dart';

class JournalStats {
  final String name;
  final int publicationCount;
  final int totalCitations;
  final double avgCitations;
  final List<Publication> publications;
  int get latestPublicationYear {
    if (publications.isEmpty) return 0;
    return publications
        .map((publication) => publication.year)
        .reduce((latest, year) => year > latest ? year : latest);
  }

  JournalStats({
    required this.name,
    required this.publicationCount,
    required this.totalCitations,
    required this.avgCitations,
    required this.publications,
  });
}

int compareJournalsByLatestPublication(JournalStats a, JournalStats b) {
  final byLatestYear = b.latestPublicationYear.compareTo(
    a.latestPublicationYear,
  );
  if (byLatestYear != 0) return byLatestYear;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
