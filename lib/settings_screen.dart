import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({required this.userId, Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTwoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _settingsTile(
            context: context,
            icon: Icons.security,
            title: 'Enable Two-Factor Authentication',
            subtitle: isTwoFactorEnabled
                ? 'Two-Factor Authentication is enabled'
                : 'Two-Factor Authentication is disabled',
            onTap: _toggleTwoFactorAuth,
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(
        value: isTwoFactorEnabled,
        onChanged: (value) => _toggleTwoFactorAuth(),
      ),
      onTap: onTap,
    );
  }

  void _toggleTwoFactorAuth() {
    setState(() {
      isTwoFactorEnabled = !isTwoFactorEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTwoFactorEnabled
              ? 'Two-Factor Authentication enabled'
              : 'Two-Factor Authentication disabled',
        ),
      ),
    );
  }
}
