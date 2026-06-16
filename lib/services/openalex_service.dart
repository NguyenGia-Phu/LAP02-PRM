import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/publication.dart';
import '../models/domain.dart';

class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';
  static const String _email = 'student@fpt.edu.vn';
  static const _timeout = Duration(seconds: 60);

  Future<List<Publication>> searchPublications(String topic, {int perPage = 50}) async {
    final encoded = Uri.encodeComponent(topic);
    final uri = Uri.parse(
      '$_baseUrl/works?filter=title.search:$encoded&per-page=$perPage'
      '&sort=cited_by_count:desc&mailto=$_email',
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch publications (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => Publication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Publication>> searchByDomainOrField({
    String? domainId,
    String? fieldId,
    int page = 1,
    int perPage = 25,
  }) async {
    String filter;
    if (fieldId != null) {
      filter = 'primary_topic.field.id:$fieldId';
    } else if (domainId != null) {
      filter = 'primary_topic.domain.id:$domainId';
    } else {
      return [];
    }
    final uri = Uri.parse(
      '$_baseUrl/works?filter=$filter&per-page=$perPage&page=$page&sort=cited_by_count:desc&mailto=$_email',
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) throw Exception('Failed (${response.statusCode})');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => Publication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Publication>> searchPublicationsByPage(
    String topic, {
    int page = 1,
    int perPage = 100,
  }) async {
    final encoded = Uri.encodeComponent(topic);
    final uri = Uri.parse(
      '$_baseUrl/works?filter=title.search:$encoded&per-page=$perPage'
      '&page=$page&mailto=$_email',
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch publications (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => Publication.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ResearchDomain>> fetchDomains() async {
    final uri = Uri.parse('$_baseUrl/domains?per-page=10&mailto=$_email');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => ResearchDomain.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> fetchSuggestedTopics() async {
    final uri = Uri.parse(
      '$_baseUrl/concepts?sort=works_count:desc&per-page=20&mailto=$_email',
    );
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => e['display_name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<Publication> getPublicationDetail(String workId) async {
    final cleanId = workId.replaceFirst('https://openalex.org/', '');
    final uri = Uri.parse('$_baseUrl/works/$cleanId?mailto=$_email');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch publication detail (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Publication.fromJson(data);
  }
}
