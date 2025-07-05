import 'package:crane/Screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:crane/Screens/help_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _messageAlertsEnabled = true;
  bool _promotionalEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeNotificationSettings();
  }

  Future<void> _initializeNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _darkMode = prefs.getBool('darkMode') ?? false;
          _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
          _messageAlertsEnabled = prefs.getBool('messageAlertsEnabled') ?? true;
          _promotionalEnabled = prefs.getBool('promotionalEnabled') ?? false;
        });
      }

      // Initialize notification channels if needed
      await _initializeNotificationChannels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize settings: $e')),
        );
      }
    }
  }

  Future<void> _initializeNotificationChannels() async {
    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: 'messages_channel',
        channelName: 'Messages',
        channelDescription: 'Channel for message notifications',
        importance: NotificationImportance.High,
        defaultColor: Colors.blue,
        ledColor: Colors.blue,
      ),
    );
  }

  Future<void> _saveNotificationPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkMode', _darkMode);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setBool('messageAlertsEnabled', _messageAlertsEnabled);
      await prefs.setBool('promotionalEnabled', _promotionalEnabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
      }
      debugPrint('Failed to save Preferences: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final isAllowed = await AwesomeNotifications().isNotificationAllowed();
        if (!isAllowed && mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Notification Permission'),
              content: const Text(
                'Please enable notifications to receive alerts',
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (Platform.isAndroid) {
                      const intent = AndroidIntent(
                        action: 'android.settings.APP_NOTIFICATION_SETTINGS',
                        arguments: {
                          'android.provider.extra.APP_PACKAGE':
                              'com.example.cirrocloudapp',
                        },
                      );
                      await intent.launch();
                    }
                    // Request permission through AwesomeNotifications
                    await AwesomeNotifications()
                        .requestPermissionToSendNotifications();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'CirroCloud',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Theme Section
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    _saveNotificationPrefs();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notifications Section
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    if (value) await _requestNotificationPermission();
                    setState(() => _notificationsEnabled = value);
                    _saveNotificationPrefs();
                  },
                ),
                if (_notificationsEnabled) ...[
                  SwitchListTile(
                    title: const Text('Message Alerts'),
                    subtitle: const Text('Get notified about new messages'),
                    value: _messageAlertsEnabled,
                    onChanged: (value) {
                      setState(() => _messageAlertsEnabled = value);
                      _saveNotificationPrefs();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Promotional Offers'),
                    subtitle: const Text('Special deals and updates'),
                    value: _promotionalEnabled,
                    onChanged: (value) {
                      setState(() => _promotionalEnabled = value);
                      _saveNotificationPrefs();
                    },
                  ),
                  ListTile(
                    title: const Text('Notification Sound'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to sound selection
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Account Section
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile Settings'),
                  onTap: () {
                    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EnhancedProfileScreen()),
    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Privacy & Security'),
                  onTap: () {
                    // Navigate to privacy
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App Section
          Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'About App',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Rate Us'),
                  onTap: () {
                    // Open app store
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () {
                    // Implement sign out
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
