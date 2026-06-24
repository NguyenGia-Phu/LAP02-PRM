import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/keyword_stats.dart';
import '../../firebase/analytics_service.dart';
import '../../widgets/publication_card.dart';
import '../home/publication_detail_screen.dart';

class KeywordDetailScreen extends StatefulWidget {
  final KeywordStats keywordStats;

  const KeywordDetailScreen({super.key, required this.keywordStats});

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logViewKeyword(widget.keywordStats.keyword);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = widget.keywordStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyword Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(stats, theme),
            const SizedBox(height: 20),
            _buildTrendSection(stats, theme),
            const SizedBox(height: 24),
            _buildAuthorsSection(stats, theme),
            const SizedBox(height: 24),
            _buildJournalsSection(stats, theme),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Related Publications (${stats.publications.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.publications.length,
              itemBuilder: (context, index) {
                final pub = stats.publications[index];
                return PublicationCard(
                  publication: pub,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublicationDetailScreen(publication: pub),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(KeywordStats stats, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tag, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stats.keyword,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total Occurrences: ${stats.frequency} papers',
            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(KeywordStats stats, ThemeData theme) {
    final sortedYears = stats.trendByYear.keys.toList()..sort();
    if (sortedYears.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(sortedYears.length, (i) {
      final year = sortedYears[i];
      final count = stats.trendByYear[year] ?? 0;
      return FlSpot(i.toDouble(), count.toDouble());
    });

    final maxVal = stats.trendByYear.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Publication Trend Over Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= sortedYears.length) return const SizedBox.shrink();
                          if (sortedYears.length > 5 && i % 2 != 0) return const SizedBox.shrink();
                          return Text('${sortedYears[i]}', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: maxVal > 5 ? (maxVal / 4).roundToDouble() : 1,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorsSection(KeywordStats stats, ThemeData theme) {
    // Sort authors by publication count
    final sortedAuthors = stats.authorPublicationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayAuthors = sortedAuthors.take(5).toList();

    if (displayAuthors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Contributing Authors',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayAuthors.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final author = displayAuthors[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                title: Text(
                  author.key,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                trailing: Chip(
                  label: Text('${author.value} papers', style: const TextStyle(fontSize: 10)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJournalsSection(KeywordStats stats, ThemeData theme) {
    if (stats.relatedJournals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Journals',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats.relatedJournals.take(8).map((journal) {
            return Chip(
              label: Text(journal, style: const TextStyle(fontSize: 11)),
              avatar: const Icon(Icons.store, size: 12, color: Colors.grey),
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
