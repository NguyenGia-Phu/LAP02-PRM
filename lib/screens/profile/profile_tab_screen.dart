import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../firebase/fcm_service.dart';
import '../../firebase/remote_config_service.dart';
import '../../firebase/crashlytics_service.dart';
import '../../firebase/storage_service.dart';
import '../../firebase/analytics_service.dart';
import '../../services/openalex_service.dart';
import '../../utils/pdf_generator.dart';
import '../../models/journal_stats.dart';
import '../../models/publication.dart';
import '../filtered_publications_screen.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  final TextEditingController _topicController = TextEditingController();
  bool _isExporting = false;
  String? _exportUrl;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _exportPdfReport(String topic) async {
    if (topic.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic to export')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportUrl = null;
    });

    try {
      final openAlex = OpenAlexService();
      final publications = await openAlex.searchPublications(topic.trim());

      if (publications.isEmpty) {
        throw Exception('No publications found for this topic');
      }

      // Calculate total publications
      final totalPubs = publications.length;

      // Calculate avg citations
      final totalCitations = publications
          .map((p) => p.citationCount)
          .fold(0, (a, b) => a + b);
      final avgCitations = totalPubs > 0 ? totalCitations / totalPubs : 0.0;

      // Calculate most active year
      final yearCounts = <int, int>{};
      for (final p in publications) {
        yearCounts[p.year] = (yearCounts[p.year] ?? 0) + 1;
      }
      int mostActiveYear = DateTime.now().year;
      int maxCount = -1;
      yearCounts.forEach((year, count) {
        if (count > maxCount) {
          maxCount = count;
          mostActiveYear = year;
        }
      });

      // Calculate top journals
      final journalMap = <String, List<Publication>>{};
      for (final p in publications) {
        final journal = p.journalName ?? 'Unknown Journal';
        journalMap.putIfAbsent(journal, () => []).add(p);
      }
      final topJournals = journalMap.entries.map((entry) {
        final name = entry.key;
        final list = entry.value;
        final jCitations = list
            .map((p) => p.citationCount)
            .fold(0, (a, b) => a + b);
        return JournalStats(
          name: name,
          publicationCount: list.length,
          totalCitations: jCitations,
          avgCitations: list.isNotEmpty ? jCitations / list.length : 0.0,
          publications: list,
        );
      }).toList();
      topJournals.sort(
        (a, b) => b.publicationCount.compareTo(a.publicationCount),
      );

      // Calculate top publications
      final topPublications = List<Publication>.from(publications);
      topPublications.sort(
        (a, b) => b.citationCount.compareTo(a.citationCount),
      );

      // Generate PDF
      final pdfBytes = await PdfGenerator.generateReport(
        topic: topic.trim(),
        totalPublications: totalPubs,
        avgCitations: avgCitations,
        mostActiveYear: mostActiveYear,
        topJournals: topJournals,
        topPublications: topPublications,
      );

      // Upload to Firebase Storage
      final storage = StorageService();
      final fileName =
          'report_${topic.trim().replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloadUrl = await storage.uploadPdfReport(pdfBytes, fileName);

      // Log Analytics
      await AnalyticsService.logExportPdf(topic.trim());

      setState(() {
        _exportUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated and uploaded successfully!'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Export PDF error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export report: $e')));
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.tryParse(urlString);
    if (url == null || (url.scheme != 'http' && url.scheme != 'https')) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid PDF URL')));
      }
      return;
    }

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('No application could open the PDF link');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening URL: $e')));
      }
    }
  }

  Future<void> _openNotificationTopic(FcmNotification notification) async {
    final topic = notification.topic?.trim();
    if (topic == null || topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This notification has no topic details')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text('Loading publications about $topic...')),
          ],
        ),
      ),
    );

    try {
      final publications = await OpenAlexService().searchPublications(
        topic,
        perPage: 20,
      );
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FilteredPublicationsScreen(
            title: 'Trending Topic',
            subtitle: topic,
            publications: publications,
            headerIcon: Icons.trending_up_rounded,
            headerColor: Colors.deepOrange,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load topic information: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final fcmService = Provider.of<FcmService>(context);
    final remoteConfig = Provider.of<RemoteConfigService>(context);
    final user = authVM.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Researcher Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: User Info Card
            _buildUserInfoCard(user, authVM, colorScheme),
            const SizedBox(height: 24),

            // Section 2: FCM Notification Center
            _buildNotificationCenter(fcmService, colorScheme),
            const SizedBox(height: 24),

            // Section 3: Report Export
            _buildReportExportSection(colorScheme),
            const SizedBox(height: 24),

            // Section 4: Remote Config
            _buildRemoteConfigSection(remoteConfig, colorScheme),
            const SizedBox(height: 24),

            // Section 5: Crashlytics Demo
            _buildCrashlyticsSection(colorScheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(
    dynamic user,
    AuthViewModel authVM,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                if (user?.photoURL != null)
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  )
                else
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Researcher',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'No email available',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authVM.signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Sign Out"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCenter(
    FcmService fcmService,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Notification Center",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                if (fcmService.notifications.isNotEmpty)
                  TextButton(
                    onPressed: () => fcmService.clearNotifications(),
                    child: const Text("Clear All"),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (fcmService.notifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 40,
                        color: Colors.grey.withOpacity(0.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "No notifications received yet",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fcmService.notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notif = fcmService.notifications[index];
                  final hasTopic = notif.topic?.trim().isNotEmpty ?? false;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: hasTopic
                        ? () => _openNotificationTopic(notif)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                notif.timestamp.toString().substring(11, 16),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                              if (hasTopic) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
                          if (hasTopic) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up_rounded,
                                    size: 15,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      notif.topic!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            notif.body,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (hasTopic) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Tap to explore related publications',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportExportSection(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.orange,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Export Trend Report",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'Enter research topic (e.g., IoT, Blockchain)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isExporting)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      "Fetching data & generating PDF...",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _exportPdfReport(_topicController.text),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text("Export PDF Report"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (_exportUrl != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                "Export Link Available:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _exportUrl!,
                        style: const TextStyle(
                          fontSize: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded),
                    color: colorScheme.primary,
                    onPressed: () => _openUrl(_exportUrl!),
                    tooltip: 'Open in Browser',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _exportUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                        ),
                      );
                    },
                    tooltip: 'Copy Link',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteConfigSection(
    RemoteConfigService remoteConfig,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Colors.teal[700], size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      "Remote Config Values",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () async {
                    await remoteConfig.refresh();
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Remote config refreshed!'),
                        ),
                      );
                    }
                  },
                  tooltip: 'Fetch Config',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildConfigRow(
              "Max Journals Displayed",
              "${remoteConfig.maxJournalsDisplayed}",
            ),
            const Divider(),
            _buildConfigRow(
              "Max Keywords Displayed",
              "${remoteConfig.maxKeywordsDisplayed}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String parameter, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            parameter,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrashlyticsSection(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_rounded,
                  color: Colors.red[700],
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Crashlytics Diagnostics",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        throw Exception(
                          "Handled diagnostic test exception - ${DateTime.now()}",
                        );
                      } catch (e, stack) {
                        await CrashlyticsService.logHandledException(e, stack);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Handled Exception logged!'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Log Exception",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await CrashlyticsService.testCrash();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Trigger App Crash",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
