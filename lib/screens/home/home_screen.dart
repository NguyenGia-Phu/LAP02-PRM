import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/publication.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/publication_card.dart';
import 'publication_detail_screen.dart';

enum SortOption { relevance, citationsDesc, citationsAsc, yearDesc, yearAsc }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  SortOption _sortOption = SortOption.relevance;

  static const _fallbackSuggestions = [
    'Artificial Intelligence',
    'Machine Learning',
    'Data Science',
    'Cybersecurity',
    'Internet of Things',
    'Blockchain',
  ];

  void _search(String topic) {
    if (topic.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<HomeViewModel>().search(topic);
    _controller.text = topic;
    setState(() => _sortOption = SortOption.relevance);
  }

  void _clearResults() {
    context.read<HomeViewModel>().clear();
    _controller.clear();
    setState(() => _sortOption = SortOption.relevance);
  }

  List<Publication> _sorted(List<Publication> pubs) {
    final list = List<Publication>.from(pubs);
    switch (_sortOption) {
      case SortOption.citationsDesc:
        list.sort((a, b) => b.citationCount.compareTo(a.citationCount));
      case SortOption.citationsAsc:
        list.sort((a, b) => a.citationCount.compareTo(b.citationCount));
      case SortOption.yearDesc:
        list.sort((a, b) => b.year.compareTo(a.year));
      case SortOption.yearAsc:
        list.sort((a, b) => a.year.compareTo(b.year));
      case SortOption.relevance:
        break;
    }
    return list;
  }

  String _sortLabel(SortOption opt) {
    switch (opt) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.citationsDesc:
        return 'Citations ↓';
      case SortOption.citationsAsc:
        return 'Citations ↑';
      case SortOption.yearDesc:
        return 'Year ↓';
      case SortOption.yearAsc:
        return 'Year ↑';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        centerTitle: true,
        actions: viewModel.isSearched
            ? [
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear Results',
                  onPressed: _clearResults,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          _buildSearchBar(viewModel),
          Expanded(child: _buildBody(viewModel)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(HomeViewModel viewModel) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Enter research topic...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => _search(_controller.text),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error: ${viewModel.error}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _search(viewModel.currentTopic),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!viewModel.isSearched) {
      return _buildSuggestions(viewModel);
    }

    if (viewModel.allPublications.isEmpty) {
      return const Center(child: Text('No publications found for this topic.'));
    }

    final sortedPubs = _sorted(viewModel.publications);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(viewModel, sortedPubs.length),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedPubs.length,
            itemBuilder: (context, index) {
              final pub = sortedPubs[index];
              return PublicationCard(
                publication: pub,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(publication: pub),
                  ),
                ),
              );
            },
          ),
          _buildPaginationFooter(viewModel),
        ],
      ),
    );
  }

  Widget _buildSuggestions(HomeViewModel viewModel) {
    final isLoadingSuggestions =
        viewModel.domains.isEmpty && viewModel.suggestedTopics.isEmpty;

    if (isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.domains.isNotEmpty) {
      return _buildDomainSuggestions(viewModel);
    }

    return _buildFlatSuggestions();
  }

  Widget _buildDomainSuggestions(HomeViewModel viewModel) {
    final domainIcons = {
      'Physical Sciences': Icons.science,
      'Social Sciences': Icons.people,
      'Health Sciences': Icons.health_and_safety,
      'Life Sciences': Icons.eco,
    };
    final domainColors = {
      'Physical Sciences': Colors.blue,
      'Social Sciences': Colors.orange,
      'Health Sciences': Colors.red,
      'Life Sciences': Colors.green,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Browse by Domain',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...viewModel.domains.map((domain) {
          final color = domainColors[domain.name] ?? Colors.purple;
          final icon = domainIcons[domain.name] ?? Icons.folder;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(
                domain.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${domain.fields.length} fields',
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: Icon(icon, size: 16, color: color),
                        label: Text(
                          'All ${domain.name}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: color.withValues(alpha: 0.1),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          context.read<HomeViewModel>().searchByDomain(domain);
                          _controller.text = domain.name;
                          setState(() => _sortOption = SortOption.relevance);
                        },
                      ),
                      ...domain.fields.map(
                        (field) => ActionChip(
                          label: Text(field.name),
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            context.read<HomeViewModel>().searchByField(field);
                            _controller.text = field.name;
                            setState(() => _sortOption = SortOption.relevance);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFlatSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Topics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fallbackSuggestions
                .map(
                  (s) =>
                      ActionChip(label: Text(s), onPressed: () => _search(s)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(HomeViewModel viewModel, int displayedCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Publications ($displayedCount / ${viewModel.totalPublications})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _buildSortMenu(),
          ],
        ),
        const SizedBox(height: 6),
        _buildFilterChips(),
      ],
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<SortOption>(
      initialValue: _sortOption,
      onSelected: (opt) => setState(() => _sortOption = opt),
      itemBuilder: (_) => SortOption.values
          .map((opt) => PopupMenuItem(value: opt, child: Text(_sortLabel(opt))))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort, size: 18),
          const SizedBox(width: 4),
          Text(
            _sortLabel(_sortOption),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Citations ↓',
            selected: _sortOption == SortOption.citationsDesc,
            onTap: () => setState(
              () => _sortOption = _sortOption == SortOption.citationsDesc
                  ? SortOption.relevance
                  : SortOption.citationsDesc,
            ),
          ),
          _buildFilterChip(
            label: 'Citations ↑',
            selected: _sortOption == SortOption.citationsAsc,
            onTap: () => setState(
              () => _sortOption = _sortOption == SortOption.citationsAsc
                  ? SortOption.relevance
                  : SortOption.citationsAsc,
            ),
          ),
          _buildFilterChip(
            label: 'Newest',
            selected: _sortOption == SortOption.yearDesc,
            onTap: () => setState(
              () => _sortOption = _sortOption == SortOption.yearDesc
                  ? SortOption.relevance
                  : SortOption.yearDesc,
            ),
          ),
          _buildFilterChip(
            label: 'Oldest',
            selected: _sortOption == SortOption.yearAsc,
            onTap: () => setState(
              () => _sortOption = _sortOption == SortOption.yearAsc
                  ? SortOption.relevance
                  : SortOption.yearAsc,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildPaginationFooter(HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'Page ${viewModel.currentDisplayPage} / ${viewModel.totalPages}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: viewModel.currentDisplayPage > 1
                    ? () => context.read<HomeViewModel>().previousPage()
                    : null,
              ),
              ...List.generate(viewModel.totalPages, (i) {
                final page = i + 1;
                final isCurrent = page == viewModel.currentDisplayPage;
                if (viewModel.totalPages > 7 &&
                    page != 1 &&
                    page != viewModel.totalPages &&
                    (page - viewModel.currentDisplayPage).abs() > 2) {
                  if (page == 2 || page == viewModel.totalPages - 1) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text('...'),
                    );
                  }
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.read<HomeViewModel>().goToPage(page),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '$page',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: viewModel.hasMore
                    ? () => context.read<HomeViewModel>().loadNextPage()
                    : null,
              ),
            ],
          ),
          if (viewModel.isLoadingMore)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Loading more...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
