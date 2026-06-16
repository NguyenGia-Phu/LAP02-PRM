import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import 'trend_analysis_screen.dart';
import 'publication_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard: ${provider.currentTopic}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Research Summary', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.article,
                  label: 'Total Publications',
                  value: '${provider.totalPublications}',
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.format_quote,
                  label: 'Avg Citations',
                  value: provider.averageCitationCount.toStringAsFixed(1),
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.trending_up,
                  label: 'Most Active Year',
                  value: '${provider.mostActiveYear}',
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.library_books,
                  label: 'Top Journal',
                  value: provider.topJournal,
                  color: Colors.purple,
                  small: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHighlightCard(
              context,
              icon: Icons.person,
              color: Colors.teal,
              label: 'Top Contributing Author',
              value: provider.topAuthor,
            ),
            const SizedBox(height: 12),
            if (provider.mostInfluentialPaper != null)
              _buildHighlightCard(
                context,
                icon: Icons.star,
                color: Colors.amber[700]!,
                label: 'Most Influential Paper',
                value: provider.mostInfluentialPaper!.title,
                subtitle: 'Citations: ${provider.mostInfluentialPaper!.citationCount}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicationDetailScreen(publication: provider.mostInfluentialPaper!),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Quick Links', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildQuickLink(
              context,
              icon: Icons.timeline,
              label: 'Publication Trend Chart',
              subtitle: 'View publications by year',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrendAnalysisScreen()),
              ),
            ),
            _buildQuickLink(
              context,
              icon: Icons.emoji_events,
              label: 'Top Influential Papers',
              subtitle: 'Ranked by citation count',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TopInfluentialPapersScreen()),
              ),
            ),
            _buildQuickLink(
              context,
              icon: Icons.library_books,
              label: 'Top Research Journals',
              subtitle: 'Most publishing journals',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrendAnalysisScreen()),
                ).then((_) {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(
    BuildContext context, {
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

  Widget _buildQuickLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool small;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
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
}
