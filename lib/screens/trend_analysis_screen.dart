import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/search_provider.dart';
import 'publication_detail_screen.dart';

class TrendAnalysisScreen extends StatefulWidget {
  const TrendAnalysisScreen({super.key});

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Trend Analysis: ${provider.currentTopic}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Year', icon: Icon(Icons.timeline)),
            Tab(text: 'Top Journals', icon: Icon(Icons.library_books)),
            Tab(text: 'Top Authors', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PublicationsByYearTab(provider: provider),
          _TopJournalsTab(provider: provider),
          _TopAuthorsTab(provider: provider),
        ],
      ),
    );
  }
}

// --- Tab 1: Publications by Year ---
class _PublicationsByYearTab extends StatelessWidget {
  final SearchProvider provider;
  const _PublicationsByYearTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final byYear = provider.publicationsByYear;
    if (byYear.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    final years = byYear.keys.toList();
    final counts = byYear.values.toList();
    final maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Publications Per Year', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
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
                        width: years.length > 20 ? 6 : 14,
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
                        if (years.length > 15 && i % 3 != 0) return const SizedBox.shrink();
                        return Transform.rotate(
                          angle: -0.5,
                          child: Text('${years[i]}', style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Most Active Year: ${provider.mostActiveYear}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: byYear.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final year = years[years.length - 1 - i];
                return ListTile(
                  dense: true,
                  leading: Text('$year', style: const TextStyle(fontWeight: FontWeight.bold)),
                  title: LinearProgressIndicator(value: byYear[year]! / maxCount),
                  trailing: Text('${byYear[year]} papers'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tab 2: Top Journals ---
class _TopJournalsTab extends StatelessWidget {
  final SearchProvider provider;
  const _TopJournalsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final journals = provider.topJournals;
    if (journals.isEmpty) {
      return const Center(child: Text('No journal data available'));
    }
    final maxCount = journals.first.value.toDouble();
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red,
      Colors.teal, Colors.amber, Colors.indigo, Colors.pink, Colors.cyan,
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Research Journals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: List.generate(journals.length > 6 ? 6 : journals.length, (i) {
                  return PieChartSectionData(
                    value: journals[i].value.toDouble(),
                    title: '${journals[i].value}',
                    color: colors[i % colors.length],
                    radius: 70,
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                  );
                }),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: journals.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors[i % colors.length],
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(journals[i].key, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Chip(label: Text('${journals[i].value}')),
                  subtitle: LinearProgressIndicator(
                    value: journals[i].value / maxCount,
                    color: colors[i % colors.length],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Tab 3: Top Authors ---
class _TopAuthorsTab extends StatelessWidget {
  final SearchProvider provider;
  const _TopAuthorsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final authors = provider.topAuthors;
    if (authors.isEmpty) {
      return const Center(child: Text('No author data available'));
    }
    final maxCount = authors.first.value.toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Contributing Authors', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Based on number of publications in this topic',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: authors.length,
              itemBuilder: (context, i) {
                final entry = authors[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            Text('${entry.value} papers',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: entry.value / maxCount,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Top Influential Papers Screen (accessible from Dashboard) ---
class TopInfluentialPapersScreen extends StatelessWidget {
  const TopInfluentialPapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SearchProvider>();
    final papers = provider.topInfluentialPapers;

    return Scaffold(
      appBar: AppBar(title: const Text('Top Influential Papers')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: papers.length,
        itemBuilder: (context, i) {
          final pub = papers[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(pub.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('Citations: ${pub.citationCount} · Year: ${pub.year}'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PublicationDetailScreen(publication: pub)),
              ),
            ),
          );
        },
      ),
    );
  }
}
