import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
          Expanded(
            child: _buildBody(viewModel),
          ),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
      return const Center(
        child: Text('No publications found for this topic.'),
      );
    }

    final sortedPubs = _sorted(viewModel.publications);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(viewModel),
          const SizedBox(height: 20),
          _buildTrendChartSection(viewModel),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
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
    final isLoadingSuggestions = viewModel.domains.isEmpty && viewModel.suggestedTopics.isEmpty;

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              title: Text(domain.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${domain.fields.length} fields', style: const TextStyle(fontSize: 12)),
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
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: color.withValues(alpha: 0.1),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          context.read<HomeViewModel>().searchByDomain(domain);
                          _controller.text = domain.name;
                          setState(() => _sortOption = SortOption.relevance);
                        },
                      ),
                      ...domain.fields.map((field) => ActionChip(
                            label: Text(field.name),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              context.read<HomeViewModel>().searchByField(field);
                              _controller.text = field.name;
                              setState(() => _sortOption = SortOption.relevance);
                            },
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

  Widget _buildFlatSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggested Topics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
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

  Widget _buildDashboardHeader(HomeViewModel viewModel) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard: ${viewModel.currentTopic}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              icon: Icons.article,
              label: 'Total Publications',
              value: '${viewModel.totalPublications}',
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.format_quote,
              label: 'Avg Citations',
              value: viewModel.averageCitationCount.toStringAsFixed(1),
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.trending_up,
              label: 'Most Active Year',
              value: '${viewModel.mostActiveYear}',
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.library_books,
              label: 'Top Journal',
              value: viewModel.topJournal,
              color: Colors.purple,
              small: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          icon: Icons.person,
          color: Colors.teal,
          label: 'Top Contributing Author',
          value: viewModel.topAuthor,
        ),
        const SizedBox(height: 12),
        if (viewModel.mostInfluentialPaper != null)
          _buildHighlightCard(
            icon: Icons.star,
            color: Colors.amber[700]!,
            label: 'Most Influential Paper',
            value: viewModel.mostInfluentialPaper!.title,
            subtitle: 'Citations: ${viewModel.mostInfluentialPaper!.citationCount}',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicationDetailScreen(publication: viewModel.mostInfluentialPaper!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool small = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: small ? 12 : 20,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildTrendChartSection(HomeViewModel viewModel) {
    final byYear = viewModel.publicationsByYear;
    if (byYear.isEmpty) {
      return const SizedBox.shrink();
    }
    final years = byYear.keys.toList();
    final counts = byYear.values.toList();
    final maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publications Per Year',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxCount * 1.2,
                  barGroups: List.generate(years.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: counts[i].toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: years.length > 15 ? 8 : 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= years.length) return const SizedBox.shrink();
                          if (years.length > 10 && i % 2 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${years[i]}',
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            onTap: () => setState(() => _sortOption =
                _sortOption == SortOption.citationsDesc ? SortOption.relevance : SortOption.citationsDesc),
          ),
          _buildFilterChip(
            label: 'Citations ↑',
            selected: _sortOption == SortOption.citationsAsc,
            onTap: () => setState(() => _sortOption =
                _sortOption == SortOption.citationsAsc ? SortOption.relevance : SortOption.citationsAsc),
          ),
          _buildFilterChip(
            label: 'Newest',
            selected: _sortOption == SortOption.yearDesc,
            onTap: () => setState(() => _sortOption =
                _sortOption == SortOption.yearDesc ? SortOption.relevance : SortOption.yearDesc),
          ),
          _buildFilterChip(
            label: 'Oldest',
            selected: _sortOption == SortOption.yearAsc,
            onTap: () => setState(() => _sortOption =
                _sortOption == SortOption.yearAsc ? SortOption.relevance : SortOption.yearAsc),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
                        color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          '$page',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurface,
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
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
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
