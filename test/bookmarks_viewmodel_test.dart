import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/models/publication.dart';
import 'package:journal_trend_analyzer/services/bookmarks_service.dart';
import 'package:journal_trend_analyzer/viewmodels/bookmarks_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'test-user';
  late Publication publication;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    publication = Publication(
      id: 'https://openalex.org/W123',
      title: 'A bookmarked publication',
      year: 2025,
      citationCount: 42,
      journalName: 'Test Journal',
      doi: 'https://doi.org/10.1000/test',
      abstractText: 'Abstract',
      authors: [Author(id: 'A1', name: 'Test Author')],
      keywords: ['testing'],
    );
  });

  test('does not create a bookmark until save is called', () async {
    final viewModel = BookmarksViewModel();
    viewModel.setUser(userId);

    expect(viewModel.items, isEmpty);
    expect(await BookmarksService().load(userId), isEmpty);

    await viewModel.save(publication);

    expect(viewModel.contains(publication.id), isTrue);
    expect(await BookmarksService().load(userId), hasLength(1));
  });

  test('toggle saves and then removes the bookmark', () async {
    final viewModel = BookmarksViewModel();
    viewModel.setUser(userId);

    expect(await viewModel.toggle(publication), isTrue);
    expect(viewModel.contains(publication.id), isTrue);

    expect(await viewModel.toggle(publication), isFalse);
    expect(viewModel.contains(publication.id), isFalse);
  });

  test('keeps bookmarks separated by Firebase user id', () async {
    final viewModel = BookmarksViewModel();
    viewModel.setUser(userId);
    await viewModel.save(publication);

    viewModel.setUser('another-user');
    await viewModel.save(
      Publication(
        id: 'W456',
        title: 'Another publication',
        year: 2024,
        citationCount: 1,
        authors: const [],
        keywords: const [],
      ),
    );

    final service = BookmarksService();
    expect(await service.load(userId), hasLength(1));
    expect(await service.load('another-user'), hasLength(1));
  });
}
