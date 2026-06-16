import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/publication.dart';
import '../providers/search_provider.dart';
import '../widgets/publication_card.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';
import 'dashboard_screen.dart';

enum SortOption { relevance, citationsDesc, citationsAsc, yearDesc, yearAsc }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  SortOption _sortOption = SortOption.relevance;

  // Fallback khi chưa load xong từ API
  static const _fallbackSuggestions = [
    'Artificial Intelligence',
    'Machine Learning',
    'Data Science',
    'Cybersecurity',
    'Internet of Things',
    'Blockchain',
  ];

  void _search(String topic) {
    FocusScope.of(context).unfocus();
    context.read<SearchProvider>().search(topic);
    _controller.text = topic;
    setState(() => _sortOption = SortOption.relevance);
  }

  void _clearResults() {
    context.read<SearchProvider>().clear();
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
      case SortOption.relevance: return 'Relevance';
      case SortOption.citationsDesc: return 'Citations ↓';
      case SortOption.citationsAsc: return 'Citations ↑';
      case SortOption.yearDesc: return 'Year ↓';
      case SortOption.yearAsc: return 'Year ↑';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final hasData = provider.allPublications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(provider),
          if (!hasData && !provider.isLoading && provider.error == null)
            _buildSuggestions(),
          _buildBody(provider),
        ],
      ),
      bottomNavigationBar: hasData
          ? BottomAppBar(
              height: 64,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomNavBtn(
                    icon: Icons.list,
                    label: 'Results',
                    selected: true,
                    onTap: _clearResults,
                  ),
                  _BottomNavBtn(
                    icon: Icons.bar_chart,
                    label: 'Trends',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrendAnalysisScreen()),
                    ),
                  ),
                  _BottomNavBtn(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSearchBar(SearchProvider provider) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _search(_controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final provider = context.watch<SearchProvider>();
    final isLoading = provider.domains.isEmpty && provider.suggestedTopics.isEmpty;

    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.domains.isNotEmpty
              ? _buildDomainSuggestions(provider)
              : _buildFlatSuggestions(provider),
    );
  }

  Widget _buildDomainSuggestions(SearchProvider provider) {
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
        Text('Browse by Domain', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...provider.domains.map((domain) {
          final color = domainColors[domain.name] ?? Colors.purple;
          final icon = domainIcons[domain.name] ?? Icons.folder;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(domain.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${domain.fields.length} fields', style: const TextStyle(fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Chip browse toàn domain
                      ActionChip(
                        avatar: Icon(icon, size: 16, color: color),
                        label: Text('All ${domain.name}',
                            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                        backgroundColor: color.withValues(alpha: 0.1),
                        onPressed: () => context.read<SearchProvider>().searchByDomain(domain),
                      ),
                      // Chips từng field
                      ...domain.fields.map((field) => ActionChip(
                        label: Text(field.name),
                        onPressed: () => context.read<SearchProvider>().searchByField(field),
                      )),
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

  Widget _buildFlatSuggestions(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested Topics', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fallbackSuggestions
                .map((s) => ActionChip(label: Text(s), onPressed: () => _search(s)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchProvider provider) {
    if (provider.allPublications.isEmpty && !provider.isLoading && provider.error == null) {
      return const SizedBox.shrink();
    }
    if (provider.isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }
    if (provider.error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error: ${provider.error}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _search(provider.currentTopic),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = _sorted(provider.publications);

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Hiển thị ${sorted.length} / ${provider.totalPublications} kết quả',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                _buildSortMenu(),
              ],
            ),
          ),
          _buildFilterChips(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: sorted.length + 1,
              itemBuilder: (context, index) {
                if (index < sorted.length) {
                  final pub = sorted[index];
                  return PublicationCard(
                    publication: pub,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicationDetailScreen(publication: pub),
                      ),
                    ),
                  );
                }
                return _buildPaginationFooter(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'Trang ${provider.currentDisplayPage} / ${provider.totalPages}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.currentDisplayPage > 1
                    ? () => context.read<SearchProvider>().previousPage()
                    : null,
              ),
              ...List.generate(provider.totalPages, (i) {
                final page = i + 1;
                final isCurrent = page == provider.currentDisplayPage;
                if (provider.totalPages > 7 &&
                    page != 1 &&
                    page != provider.totalPages &&
                    (page - provider.currentDisplayPage).abs() > 2) {
                  if (page == 2 || page == provider.totalPages - 1) {
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
                    onTap: () => context.read<SearchProvider>().goToPage(page),
                    child: Container(
                      width: 32, height: 32,
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
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
                onPressed: provider.hasMore
                    ? () => context.read<SearchProvider>().loadNextPage()
                    : null,
              ),
            ],
          ),
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Đang tải thêm...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
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
          Text(_sortLabel(_sortOption),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  )),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Citations ↓',
            selected: _sortOption == SortOption.citationsDesc,
            onTap: () => setState(() => _sortOption = _sortOption == SortOption.citationsDesc
                ? SortOption.relevance : SortOption.citationsDesc),
          ),
          _FilterChip(
            label: 'Citations ↑',
            selected: _sortOption == SortOption.citationsAsc,
            onTap: () => setState(() => _sortOption = _sortOption == SortOption.citationsAsc
                ? SortOption.relevance : SortOption.citationsAsc),
          ),
          _FilterChip(
            label: 'Newest',
            selected: _sortOption == SortOption.yearDesc,
            onTap: () => setState(() => _sortOption = _sortOption == SortOption.yearDesc
                ? SortOption.relevance : SortOption.yearDesc),
          ),
          _FilterChip(
            label: 'Oldest',
            selected: _sortOption == SortOption.yearAsc,
            onTap: () => setState(() => _sortOption = _sortOption == SortOption.yearAsc
                ? SortOption.relevance : SortOption.yearAsc),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _BottomNavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
      ),
    );
  }
}
