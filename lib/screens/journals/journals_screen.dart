import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/journals_viewmodel.dart';
import '../../firebase/remote_config_service.dart';
import 'journal_detail_screen.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  final _controller = TextEditingController();
  String _currentSort = 'Publications';

  final List<Color> _chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
  ];

  void _search(String topic) {
    if (topic.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<JournalsViewModel>().loadJournals(topic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<JournalsViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Contributor Analysis'),
        centerTitle: true,
        actions: viewModel.journals.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear Results',
                  onPressed: () {
                    viewModel.clear();
                    _controller.clear();
                  },
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          _buildSearchBar(viewModel),
          Expanded(child: _buildBody(viewModel, theme)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(JournalsViewModel viewModel) {
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
                hintText: 'Enter topic for journal analysis...',
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
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(JournalsViewModel viewModel, ThemeData theme) {
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

    if (viewModel.journals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_books, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                viewModel.currentTopic.isEmpty
                    ? 'Enter a topic above to analyze publishing journals.'
                    : 'No journals found for this topic.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis for: ${viewModel.currentTopic}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOverallMetrics(viewModel),
          const SizedBox(height: 20),
          _buildChartSection(viewModel),
          const SizedBox(height: 24),
          _buildRankedListSection(viewModel),
        ],
      ),
    );
  }

  Widget _buildOverallMetrics(JournalsViewModel viewModel) {
    // Calculate total publications & average citation rate across all grouped journals
    final totalPublications = viewModel.journals.fold<int>(0, (sum, j) => sum + j.publicationCount);
    final totalCitations = viewModel.journals.fold<int>(0, (sum, j) => sum + j.totalCitations);
    final overallAvgCitations = totalPublications == 0 ? 0.0 : totalCitations / totalPublications;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.store,
            color: Colors.purple,
            value: '${viewModel.journals.length}',
            label: 'Unique Journals',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.format_quote,
            color: Colors.green,
            value: overallAvgCitations.toStringAsFixed(1),
            label: 'Avg Citation Rate',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChartSection(JournalsViewModel viewModel) {
    final list = viewModel.journals;
    final topCount = list.length > 5 ? 5 : list.length;
    final topJournals = list.take(topCount).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribution of Top Journals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(topCount, (i) {
                          final journal = topJournals[i];
                          return PieChartSectionData(
                            value: journal.publicationCount.toDouble(),
                            title: '${journal.publicationCount}',
                            color: _chartColors[i % _chartColors.length],
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        sectionsSpace: 2,
                        centerSpaceRadius: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(topCount, (i) {
                      final journal = topJournals[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _chartColors[i % _chartColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                journal.name,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedListSection(JournalsViewModel viewModel) {
    final remoteConfig = context.read<RemoteConfigService>();
    final list = viewModel.journals.take(remoteConfig.maxJournalsDisplayed).toList();
    final maxPubCount = list.isEmpty ? 1.0 : list.map((j) => j.publicationCount).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ranked Journals List',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            _buildSortingDropdown(viewModel),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final journal = list[i];
            final color = _chartColors[i % _chartColors.length];

            return Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                title: Text(
                  journal.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Papers: ${journal.publicationCount}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Text('Citations: ${journal.totalCitations}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: journal.publicationCount / maxPubCount,
                          backgroundColor: Colors.grey[200],
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalDetailScreen(journal: journal),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSortingDropdown(JournalsViewModel viewModel) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      initialValue: _currentSort,
      onSelected: (val) {
        setState(() => _currentSort = val);
        if (val == 'Publications') {
          viewModel.sortByPublicationCount();
        } else if (val == 'Total Citations') {
          viewModel.sortByTotalCitations();
        } else if (val == 'Avg Citations') {
          viewModel.sortByAvgCitations();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'Publications', child: Text('Publications')),
        const PopupMenuItem(value: 'Total Citations', child: Text('Total Citations')),
        const PopupMenuItem(value: 'Avg Citations', child: Text('Avg Citations')),
      ],
    );
  }
}
