import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/journal_stats.dart';
import 'package:journal_trend_analyzer/models/publication.dart';

Publication publication(String id, int year) {
  return Publication(
    id: id,
    title: id,
    year: year,
    citationCount: 0,
    authors: const [],
    keywords: const [],
  );
}

JournalStats journal(String name, List<int> years) {
  final publications = [
    for (var i = 0; i < years.length; i++) publication('$name-$i', years[i]),
  ];
  return JournalStats(
    name: name,
    publicationCount: publications.length,
    totalCitations: 0,
    avgCitations: 0,
    publications: publications,
  );
}

void main() {
  test('latestPublicationYear returns the newest publication year', () {
    expect(
      journal('Journal A', [2021, 2025, 2023]).latestPublicationYear,
      2025,
    );
  });

  test('journal comparator sorts newest journals first', () {
    final journals = [
      journal('Older Journal', [2020, 2022]),
      journal('Newest Journal', [2024, 2026]),
      journal('Middle Journal', [2023]),
    ]..sort(compareJournalsByLatestPublication);

    expect(journals.map((item) => item.name), [
      'Newest Journal',
      'Middle Journal',
      'Older Journal',
    ]);
  });
}
