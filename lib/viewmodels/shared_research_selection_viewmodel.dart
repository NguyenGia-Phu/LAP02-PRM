import 'package:flutter/foundation.dart';

enum ResearchSelectionType { text, domain, field }

class SharedResearchSelectionViewModel extends ChangeNotifier {
  String _label = '';
  String? _domainId;
  String? _fieldId;
  ResearchSelectionType _type = ResearchSelectionType.text;

  String get label => _label;
  String? get domainId => _domainId;
  String? get fieldId => _fieldId;
  ResearchSelectionType get type => _type;
  bool get hasSelection => _label.isNotEmpty;

  String get key =>
      '${_type.name}|$_label|${_domainId ?? ''}|${_fieldId ?? ''}';

  void setText(String label) {
    _set(label: label, type: ResearchSelectionType.text);
  }

  void setDomain({required String label, required String domainId}) {
    _set(label: label, type: ResearchSelectionType.domain, domainId: domainId);
  }

  void setField({required String label, required String fieldId}) {
    _set(label: label, type: ResearchSelectionType.field, fieldId: fieldId);
  }

  void _set({
    required String label,
    required ResearchSelectionType type,
    String? domainId,
    String? fieldId,
  }) {
    final normalized = label.trim();
    if (_label == normalized &&
        _type == type &&
        _domainId == domainId &&
        _fieldId == fieldId) {
      return;
    }

    _label = normalized;
    _type = type;
    _domainId = domainId;
    _fieldId = fieldId;
    notifyListeners();
  }

  void clear() {
    if (_label.isEmpty && _domainId == null && _fieldId == null) return;

    _label = '';
    _type = ResearchSelectionType.text;
    _domainId = null;
    _fieldId = null;
    notifyListeners();
  }
}
