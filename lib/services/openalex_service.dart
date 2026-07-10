import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/publication.dart';
import '../models/domain.dart';

class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';
  static const String _email = 'ndanthanh161@gmail.com';
  static const String _apiKey = 'UsbP7qDN46xJEnWZjKyeLI';
  static const _timeout = Duration(seconds: 60);

  Future<Map<String, dynamic>> _getJson(Uri uri, String label) async {
    debugPrint('[OpenAlex] GET $label: $uri');
    try {
      final response = await http.get(uri).timeout(_timeout);
      debugPrint(
        '[OpenAlex] $label status=${response.statusCode} bytes=${response.body.length}',
      );
      if (response.statusCode != 200) {
        final preview = response.body.length > 300
            ? response.body.substring(0, 300)
            : response.body;
        throw Exception('$label failed (${response.statusCode}): $preview');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('[OpenAlex] $label error: $e');
      debugPrintStack(stackTrace: st, label: '[OpenAlex] $label stack');
      rethrow;
    }
  }

  List<Publication> _parsePublications(
    Map<String, dynamic> data,
    String label,
  ) {
    final results = data['results'] as List<dynamic>? ?? [];
    debugPrint('[OpenAlex] $label results=${results.length}');
    return results
        .map((e) => Publication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Publication>> searchPublications(
    String topic, {
    int perPage = 50,
  }) async {
    final encoded = Uri.encodeComponent(topic);
    final uri = Uri.parse(
      '$_baseUrl/works?filter=title.search:$encoded&per-page=$perPage'
      '&sort=cited_by_count:desc&api_key=$_apiKey',
    );
    final data = await _getJson(uri, 'searchPublications topic="$topic"');
    return _parsePublications(data, 'searchPublications topic="$topic"');
  }

  Future<List<Publication>> searchByDomainOrField({
    String? domainId,
    String? fieldId,
    int page = 1,
    int perPage = 25,
  }) async {
    String filter;
    String label;
    if (fieldId != null) {
      filter = 'primary_topic.field.id:$fieldId';
      label = 'searchByField fieldId=$fieldId page=$page';
    } else if (domainId != null) {
      filter = 'primary_topic.domain.id:$domainId';
      label = 'searchByDomain domainId=$domainId page=$page';
    } else {
      debugPrint('[OpenAlex] searchByDomainOrField skipped: no id');
      return [];
    }
    final uri = Uri.parse(
      '$_baseUrl/works?filter=$filter&per-page=$perPage&page=$page&sort=cited_by_count:desc&api_key=$_apiKey',
    );
    final data = await _getJson(uri, label);
    return _parsePublications(data, label);
  }

  Future<List<Publication>> searchPublicationsByPage(
    String topic, {
    int page = 1,
    int perPage = 100,
  }) async {
    final encoded = Uri.encodeComponent(topic);
    final uri = Uri.parse(
      '$_baseUrl/works?filter=title.search:$encoded&per-page=$perPage'
      '&page=$page&api_key=$_apiKey',
    );
    final label = 'searchByPage topic="$topic" page=$page';
    final data = await _getJson(uri, label);
    return _parsePublications(data, label);
  }

  Future<List<ResearchDomain>> fetchDomains() async {
    final uri = Uri.parse('$_baseUrl/domains?per-page=10&api_key=$_apiKey');
    final data = await _getJson(uri, 'fetchDomains');
    final results = data['results'] as List<dynamic>? ?? [];
    debugPrint('[OpenAlex] fetchDomains results=${results.length}');
    return results
        .map((e) => ResearchDomain.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchSuggestedTopics() async {
    final uri = Uri.parse(
      '$_baseUrl/concepts?sort=works_count:desc&per-page=20&api_key=$_apiKey',
    );
    final data = await _getJson(uri, 'fetchSuggestedTopics');
    final results = data['results'] as List<dynamic>? ?? [];
    debugPrint('[OpenAlex] fetchSuggestedTopics results=${results.length}');
    return results
        .map((e) => e['display_name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<Publication> getPublicationDetail(String workId) async {
    final cleanId = workId.replaceFirst('https://openalex.org/', '');
    final uri = Uri.parse('$_baseUrl/works/$cleanId?api_key=$_apiKey');
    final data = await _getJson(uri, 'getPublicationDetail workId=$cleanId');
    return Publication.fromJson(data);
  }

  Future<List<Publication>> searchByKeyword(
    String keyword, {
    int page = 1,
    int perPage = 25,
  }) async {
    final encoded = Uri.encodeComponent(keyword);
    final uri = Uri.parse(
      '$_baseUrl/works?filter=keywords.keyword:$encoded&per-page=$perPage'
      '&page=$page&sort=cited_by_count:desc&api_key=$_apiKey',
    );
    final label = 'searchByKeyword keyword="$keyword" page=$page';
    final data = await _getJson(uri, label);
    return _parsePublications(data, label);
  }

  List<String> getKeywordsFromPublications(List<Publication> publications) {
    final keywords = <String>{};
    for (final pub in publications) {
      for (final kw in pub.keywords) {
        final trimmed = kw.trim();
        if (trimmed.isNotEmpty) {
          keywords.add(trimmed);
        }
      }
    }
    return keywords.toList();
  }
}
