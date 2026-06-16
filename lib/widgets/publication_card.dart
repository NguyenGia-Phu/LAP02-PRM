import 'package:flutter/material.dart';
import '../models/publication.dart';

class PublicationCard extends StatelessWidget {
  final Publication publication;
  final VoidCallback onTap;

  const PublicationCard({super.key, required this.publication, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                publication.title,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (publication.journalName != null)
                Text(
                  publication.journalName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${publication.year}', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(Icons.format_quote, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${publication.citationCount} citations', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
              if (publication.authors.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  publication.authors.take(3).map((a) => a.name).join(', ') +
                      (publication.authors.length > 3 ? ' et al.' : ''),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
