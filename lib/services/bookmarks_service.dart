import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmarked_publication.dart';

class BookmarksService {
  static const _storageKeyPrefix = 'bookmarked_publications_';

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';

  Future<List<BookmarkedPublication>> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_storageKey(userId));
    if (rawValue == null || rawValue.isEmpty) return [];

    try {
      final decoded = jsonDecode(rawValue) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(BookmarkedPublication.fromJson)
          .where((item) => item.publication.id.isNotEmpty)
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> save(
    String userId,
    List<BookmarkedPublication> publications,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey(userId),
      jsonEncode(publications.map((item) => item.toJson()).toList()),
    );
  }
}
