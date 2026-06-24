import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final user = authVM.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Researcher Profile"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Section 1: User Information Header Card
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.primary.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    // Avatar
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
                    // Names
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
                            user?.email ?? 'No email',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Demo / Upcoming Integrations
            _buildProfileSectionHeader("Firebase Integrations (Phase 7-8)"),
            const SizedBox(height: 12),

            // FCM Notification Center Placeholder
            _buildFeaturePlaceholderCard(
              context,
              Icons.notifications_active_rounded,
              "Notification Center (FCM)",
              "Receive and view push notifications from Firebase Cloud Messaging.",
              colorScheme.primary,
            ),
            const SizedBox(height: 12),

            // PDF Export Placeholder
            _buildFeaturePlaceholderCard(
              context,
              Icons.picture_as_pdf_rounded,
              "Report Export (Storage)",
              "Generate PDF analytics reports and upload directly to Firebase Storage.",
              Colors.orange[700]!,
            ),
            const SizedBox(height: 12),

            // Remote Config Placeholder
            _buildFeaturePlaceholderCard(
              context,
              Icons.tune_rounded,
              "Remote Config Demo",
              "Dynamically fetch remote parameters (e.g. maximum items to display).",
              Colors.teal[700]!,
            ),
            const SizedBox(height: 12),

            // Crashlytics Placeholder
            _buildFeaturePlaceholderCard(
              context,
              Icons.bug_report_rounded,
              "Crashlytics Demo",
              "Simulate crashes or test handled exceptions to monitor stability.",
              Colors.red[700]!,
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => authVM.signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Sign Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red[100]!),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFeaturePlaceholderCard(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
    Color iconColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            desc,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "SOON",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
