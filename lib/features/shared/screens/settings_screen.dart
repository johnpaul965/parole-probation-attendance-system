import 'package:flutter/material.dart';
import 'package:last/core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminders = true;
  bool _missedAlerts = true;
  bool _pushEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.reports,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Attendance Reminders'),
            subtitle: const Text('Notify parolees before scheduled check-ins'),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          SwitchListTile(
            title: const Text('Missed Attendance Alerts'),
            subtitle: const Text('Alert officers when check-ins are missed'),
            value: _missedAlerts,
            onChanged: (v) => setState(() => _missedAlerts = v),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          const Divider(),
          const _SectionHeader('System'),
          const ListTile(
            leading: Icon(Icons.cloud_done_outlined),
            title: Text('Data Source'),
            subtitle: Text('Firebase Firestore (real-time)'),
            trailing: Chip(
              label: Text('Live'),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8),
      ),
    );
  }
}
