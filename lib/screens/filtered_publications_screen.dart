import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../widgets/publication_card.dart';
import 'home/publication_detail_screen.dart';

class FilteredPublicationsScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Publication> publications;
  final IconData headerIcon;
  final Color headerColor;

  const FilteredPublicationsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.publications,
    this.headerIcon = Icons.article,
    this.headerColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<Publication>.from(publications)
      ..sort((a, b) => b.citationCount.compareTo(a.citationCount));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            color: headerColor.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: headerColor.withValues(alpha: 0.2),
                  child: Icon(headerIcon, color: headerColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subtitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text('${sorted.length} publications · sorted by citations',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: sorted.isEmpty
                ? const Center(child: Text('No publications found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
