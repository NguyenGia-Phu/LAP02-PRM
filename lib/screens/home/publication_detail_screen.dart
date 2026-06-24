import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/publication.dart';
import '../../firebase/analytics_service.dart';

class PublicationDetailScreen extends StatefulWidget {
  final Publication publication;

  const PublicationDetailScreen({super.key, required this.publication});

  @override
  State<PublicationDetailScreen> createState() => _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logViewPublication(
      widget.publication.title,
      widget.publication.year,
    );
  }

  Future<void> _launchDoi(String doi) async {
    Uri url;
    if (doi.startsWith('http://') || doi.startsWith('https://')) {
      url = Uri.parse(doi);
    } else {
      url = Uri.parse('https://doi.org/$doi');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      debugPrint("Error launching DOI: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open DOI link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pub = widget.publication;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Detail'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Card
            Card(
              elevation: 3,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.3),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pub.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, Icons.calendar_today_rounded, 'Year', '${pub.year}'),
                    _buildInfoRow(context, Icons.format_quote_rounded, 'Citations', '${pub.citationCount}'),
                    if (pub.journalName != null && pub.journalName!.isNotEmpty)
                      _buildInfoRow(context, Icons.library_books_rounded, 'Journal', pub.journalName!),
                    if (pub.doi != null && pub.doi!.isNotEmpty)
                      _buildInfoRow(context, Icons.link_rounded, 'DOI', pub.doi!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Open Link Button if DOI available
            if (pub.doi != null && pub.doi!.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _launchDoi(pub.doi!),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Publication Link'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Authors Section
            if (pub.authors.isNotEmpty) ...[
              Text(
                'Authors',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pub.authors.map((a) {
                  return Chip(
                    label: Text(a.name),
                    avatar: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                      child: Text(
                        a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Abstract Section
            if (pub.abstractText != null && pub.abstractText!.isNotEmpty) ...[
              Text(
                'Abstract',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  pub.abstractText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
