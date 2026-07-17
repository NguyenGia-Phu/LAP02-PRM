import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/publication_url.dart';

void main() {
  test('keeps a valid OpenAlex DOI URL unchanged', () {
    expect(
      publicationUrlFromDoi('https://doi.org/10.1000/test').toString(),
      'https://doi.org/10.1000/test',
    );
  });

  test('converts a raw DOI into an HTTPS URL', () {
    expect(
      publicationUrlFromDoi('10.1000/test').toString(),
      'https://doi.org/10.1000/test',
    );
  });

  test('supports DOI prefixes returned by different APIs', () {
    expect(
      publicationUrlFromDoi('doi: 10.1000/test').toString(),
      'https://doi.org/10.1000/test',
    );
    expect(
      publicationUrlFromDoi('doi.org/10.1000/test').toString(),
      'https://doi.org/10.1000/test',
    );
  });

  test('rejects empty or invalid DOI values', () {
    expect(publicationUrlFromDoi(''), isNull);
    expect(publicationUrlFromDoi('not a doi'), isNull);
  });
}
