import 'publication.dart';

class BookmarkedPublication {
  final Publication publication;
  final DateTime savedAt;

  const BookmarkedPublication({
    required this.publication,
    required this.savedAt,
  });

  factory BookmarkedPublication.fromJson(Map<String, dynamic> json) {
    final authors = (json['authors'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (author) => Author(
            id: author['id'] as String? ?? '',
            name: author['name'] as String? ?? 'Unknown',
          ),
        )
        .toList();

    return BookmarkedPublication(
      publication: Publication(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'No Title',
        year: json['year'] as int? ?? 0,
        citationCount: json['citationCount'] as int? ?? 0,
        journalName: json['journalName'] as String?,
        doi: json['doi'] as String?,
        abstractText: json['abstractText'] as String?,
        authors: authors,
        keywords: (json['keywords'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      ),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': publication.id,
      'title': publication.title,
      'year': publication.year,
      'citationCount': publication.citationCount,
      'journalName': publication.journalName,
      'doi': publication.doi,
      'abstractText': publication.abstractText,
      'authors': publication.authors
          .map((author) => {'id': author.id, 'name': author.name})
          .toList(),
      'keywords': publication.keywords,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
