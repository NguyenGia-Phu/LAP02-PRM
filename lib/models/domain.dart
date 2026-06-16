class ResearchDomain {
  final String id;
  final String name;
  final List<ResearchField> fields;

  ResearchDomain({required this.id, required this.name, required this.fields});

  factory ResearchDomain.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? '';
    final numId = rawId.split('/').last;
    final fields = (json['fields'] as List<dynamic>? ?? []).map((f) {
      final fm = f as Map<String, dynamic>;
      final fId = (fm['id'] as String? ?? '').split('/').last;
      return ResearchField(id: fId, name: fm['display_name'] as String? ?? '');
    }).toList();
    return ResearchDomain(id: numId, name: json['display_name'] as String? ?? '', fields: fields);
  }
}

class ResearchField {
  final String id;
  final String name;

  ResearchField({required this.id, required this.name});
}
