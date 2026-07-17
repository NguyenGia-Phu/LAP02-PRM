import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bookmarked_publication.dart';
import '../models/publication.dart';
import '../services/bookmarks_service.dart';

class BookmarksViewModel extends ChangeNotifier {
  static const maxBookmarks = 100;

  final BookmarksService _service;
  String? _userId;
  List<BookmarkedPublication> _items = [];
  Future<void>? _loadFuture;
  int _loadGeneration = 0;
  bool _isLoading = false;

  BookmarksViewModel({BookmarksService? service})
    : _service = service ?? BookmarksService();

  List<BookmarkedPublication> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  bool contains(String publicationId) {
    return _items.any((item) => item.publication.id == publicationId);
  }

  void setUser(String? userId) {
    if (_userId == userId) return;

    _userId = userId;
    _items = [];
    _isLoading = userId != null;
    final generation = ++_loadGeneration;
    notifyListeners();

    if (userId == null) {
      _loadFuture = null;
      return;
    }

    _loadFuture = _load(userId, generation);
  }

  Future<void> _load(String userId, int generation) async {
    try {
      final loadedItems = await _service.load(userId);
      if (_userId != userId || generation != _loadGeneration) return;
      _items = loadedItems;
    } catch (error) {
      debugPrint('Could not load bookmarks: $error');
    } finally {
      if (_userId == userId && generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> save(Publication publication) async {
    final userId = _userId;
    if (userId == null || publication.id.isEmpty) return;

    await _loadFuture;
    if (_userId != userId || contains(publication.id)) return;

    _items.insert(
      0,
      BookmarkedPublication(publication: publication, savedAt: DateTime.now()),
    );
    if (_items.length > maxBookmarks) {
      _items = _items.take(maxBookmarks).toList();
    }
    notifyListeners();
    await _persist(userId);
  }

  Future<bool> toggle(Publication publication) async {
    if (contains(publication.id)) {
      await remove(publication.id);
      return false;
    }

    await save(publication);
    return contains(publication.id);
  }

  Future<void> remove(String publicationId) async {
    final userId = _userId;
    if (userId == null) return;

    _items.removeWhere((item) => item.publication.id == publicationId);
    notifyListeners();
    await _persist(userId);
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) return;

    _items = [];
    notifyListeners();
    await _persist(userId);
  }

  Future<void> _persist(String userId) async {
    try {
      await _service.save(userId, _items);
    } catch (error) {
      debugPrint('Could not save bookmarks: $error');
    }
  }
}
