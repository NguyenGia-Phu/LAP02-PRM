class Publication {
  final String id;
  final String title;
  final int year;
  final int citationCount;
  final String? journalName;
  final String? doi;
  final String? abstractText;
  final List<Author> authors;
  final List<String> keywords;

  Publication({
    required this.id,
    required this.title,
    required this.year,
    required this.citationCount,
    this.journalName,
    this.doi,
    this.abstractText,
    required this.authors,
    required this.keywords,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    final authorships = (json['authorships'] as List<dynamic>? ?? []);
    final authors = authorships.map((a) {
      final author = a['author'] as Map<String, dynamic>? ?? {};
      return Author(
        id: author['id'] as String? ?? '',
        name: author['display_name'] as String? ?? 'Unknown',
      );
    }).toList();

    String? journalName;
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    if (primaryLocation != null) {
      final source = primaryLocation['source'] as Map<String, dynamic>?;
      journalName = source?['display_name'] as String?;
    }

    String? abstractText;
    final invertedIndex = json['abstract_inverted_index'] as Map<String, dynamic>?;
    if (invertedIndex != null) {
      abstractText = _reconstructAbstract(invertedIndex);
    }

    // Parse keywords / concepts
    List<String> keywords = [];
    final rawKeywords = json['keywords'] as List<dynamic>?;
    if (rawKeywords != null) {
      keywords = rawKeywords
          .map((k) => k['display_name'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (keywords.isEmpty) {
      final rawConcepts = json['concepts'] as List<dynamic>?;
      if (rawConcepts != null) {
        keywords = rawConcepts
            .map((c) => c['display_name'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    if (keywords.isEmpty) {
      final text = '${json['title'] ?? ''} ${abstractText ?? ''}'.toLowerCase();
      final words = text.replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
      final stopWords = {
        'the', 'a', 'an', 'and', 'of', 'to', 'in', 'for', 'with', 'on', 'at',
        'by', 'from', 'is', 'are', 'was', 'were', 'that', 'this', 'using',
        'used', 'use', 'proposed', 'paper', 'results', 'based', 'analysis',
        'system', 'method', 'model'
      };
      keywords = words
          .where((w) => w.length > 4 && !stopWords.contains(w))
          .take(5)
          .toList();
    }

    return Publication(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      year: json['publication_year'] as int? ?? 0,
      citationCount: json['cited_by_count'] as int? ?? 0,
      journalName: journalName,
      doi: json['doi'] as String?,
      abstractText: abstractText,
      authors: authors,
      keywords: keywords,
    );
  }

  static String _reconstructAbstract(Map<String, dynamic> invertedIndex) {
    final positions = <int, String>{};
    invertedIndex.forEach((word, posList) {
      for (final pos in (posList as List)) {
        positions[pos as int] = word;
      }
    });
    if (positions.isEmpty) return '';
    final sorted = positions.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => e.value).join(' ');
  }
}

class Author {
  final String id;
  final String name;

  Author({required this.id, required this.name});
}
