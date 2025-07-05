import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Getting Started'),
            _buildFAQItem(
              question: 'How do I create a new task?',
              answer: 'Tap the + button on the home screen. Fill in the task details and tap "Create Task".',
            ),
            _buildFAQItem(
              question: 'How do I mark a task as complete?',
              answer: 'Swipe left on the task or tap the checkbox next to the task.',
            ),
            _buildFAQItem(
              question: 'Can I set due dates for tasks?',
              answer: 'Yes, when creating or editing a task, tap the date field to select a due date.',
            ),

            _buildSectionHeader('Task Management'),
            _buildFAQItem(
              question: 'How do I prioritize tasks?',
              answer: 'Tasks are automatically organized by due date. You can also tag tasks with priority levels (High/Medium/Low).',
            ),
            _buildFAQItem(
              question: 'Where do completed tasks go?',
              answer: 'Completed tasks move to the "Completed" tab where you can view them or clear them all.',
            ),
            _buildFAQItem(
              question: 'Can I recover deleted tasks?',
              answer: 'Currently, deleted tasks cannot be recovered. Please be careful when deleting.',
            ),

            _buildSectionHeader('Troubleshooting'),
            _buildFAQItem(
              question: 'The app crashes when I try to save a task',
              answer: 'Try restarting the app. If the problem persists, reinstall the app (your data will be preserved).',
            ),
            _buildFAQItem(
              question: 'I can\'t see my tasks',
              answer: 'Check if you\'re filtering tasks. Try refreshing the screen or switching between tabs.',
            ),
            _buildFAQItem(
              question: 'The app is running slowly',
              answer: 'Try closing other apps to free up memory. If you have many tasks, consider archiving old ones.',
            ),

            _buildSectionHeader('Account & Data'),
            _buildFAQItem(
              question: 'How do I backup my tasks?',
              answer: 'Your tasks are automatically saved to your device. For cloud backup, use the export feature in Settings.',
            ),
            _buildFAQItem(
              question: 'Can I use the app on multiple devices?',
              answer: 'Currently, tasks are stored locally on each device. We\'re working on cloud sync for future versions.',
            ),

            _buildSectionHeader('Contact Support'),
            const SizedBox(height: 16),
            _buildContactOption(
              icon: Icons.email,
              label: 'Email us at support@cranetech.com',
              onTap: () => _launchEmail(),
            ),
            _buildContactOption(
              icon: Icons.phone,
              label: 'Call support: +256 (701) 01-5233',
              onTap: () => _launchPhone(),
            ),
            _buildContactOption(
              icon: Icons.language,
              label: 'Visit our website',
              onTap: () => _launchWebsite(),
            ),
            
            const SizedBox(height: 30),
            Center(
              child: Text(
                'App Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade700),
      title: Text(label),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@cranetech.com',
      queryParameters: {'subject': 'Task App Support Request'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+256701015233',
    );
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    }
  }

  Future<void> _launchWebsite() async {
    const String url = 'https://www.cranetech.com/support';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}