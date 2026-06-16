import 'package:flutter/material.dart';
import '../models/publication.dart';

class PublicationDetailScreen extends StatelessWidget {
  final Publication publication;

  const PublicationDetailScreen({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publication Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(publication.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.calendar_today, 'Year', '${publication.year}'),
            _buildInfoRow(context, Icons.format_quote, 'Citations', '${publication.citationCount}'),
            if (publication.journalName != null)
              _buildInfoRow(context, Icons.library_books, 'Journal', publication.journalName!),
            if (publication.doi != null)
              _buildInfoRow(context, Icons.link, 'DOI', publication.doi!),
            const SizedBox(height: 16),
            if (publication.authors.isNotEmpty) ...[
              Text('Authors', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: publication.authors
                    .map((a) => Chip(label: Text(a.name)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (publication.abstractText != null && publication.abstractText!.isNotEmpty) ...[
              Text('Abstract', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(publication.abstractText!, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
