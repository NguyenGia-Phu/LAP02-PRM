Uri? publicationUrlFromDoi(String rawDoi) {
  var value = rawDoi.trim();
  if (value.isEmpty) return null;

  final lowerValue = value.toLowerCase();
  if (lowerValue.startsWith('http://') || lowerValue.startsWith('https://')) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  if (lowerValue.startsWith('doi:')) {
    value = value.substring(4).trim();
  } else if (lowerValue.startsWith('doi.org/')) {
    value = value.substring('doi.org/'.length);
  } else if (lowerValue.startsWith('dx.doi.org/')) {
    value = value.substring('dx.doi.org/'.length);
  }

  value = value.replaceFirst(RegExp(r'^/+'), '').trim();
  if (!value.toLowerCase().startsWith('10.') || RegExp(r'\s').hasMatch(value)) {
    return null;
  }

  return Uri.https('doi.org', '/$value');
}
