import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // New import
import 'package:gapshap/theme_mode_notifier.dart'; // New import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Dummy values for settings
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _callNotifications = true;
  final String _notificationTone = 'Default';
  String _vibration = 'Default';
  String _popupNotification = 'Always';
  String _lastSeenVisibility = 'Everyone';
  String _profilePhotoVisibility = 'Everyone';
  String _aboutVisibility = 'Everyone';
  String _statusVisibility = 'All';
  bool _readReceipts = true;
  String _disappearingMessages = 'Off';
  bool _fingerprintLock = false;
  String _fontSize = 'Medium';
  String _theme = 'System default'; // This will be updated by ThemeModeNotifier

  @override
  void initState() {
    super.initState();
    // Initialize _theme based on current ThemeModeNotifier value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentThemeMode = Provider.of<ThemeModeNotifier>(context, listen: false).themeMode;
      setState(() {
        if (currentThemeMode == ThemeMode.light) {
          _theme = 'Light';
        } else if (currentThemeMode == ThemeMode.dark) {
          _theme = 'Dark';
        } else {
          _theme = 'System default';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionTitle('Account'),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Privacy Settings')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Two-step verification',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Two-step verification')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.phone_outlined,
            title: 'Change number',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Change number')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'Request account info',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Request account info')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline,
            title: 'Delete account',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Delete account')),
              );
            },
          ),
          _buildSectionTitle('Chats'),
          _buildSettingsTile(
            context,
            icon: Icons.backup_outlined,
            title: 'Chat backup',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Chat backup')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.history,
            title: 'Chat history',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Chat history')),
              );
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.font_download_outlined,
            title: 'Font size',
            value: _fontSize,
            items: const ['Small', 'Medium', 'Large'],
            onChanged: (newValue) {
              setState(() {
                _fontSize = newValue!;
              });
              // TODO: Implement font size change logic
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.color_lens_outlined,
            title: 'Theme',
            value: _theme,
            items: const ['Light', 'Dark', 'System default'],
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _theme = newValue;
                });
                ThemeMode newThemeMode;
                if (newValue == 'Light') {
                  newThemeMode = ThemeMode.light;
                } else if (newValue == 'Dark') {
                  newThemeMode = ThemeMode.dark;
                } else {
                  newThemeMode = ThemeMode.system;
                }
                Provider.of<ThemeModeNotifier>(context, listen: false).updateThemeMode(newThemeMode);
              }
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.wallpaper_outlined,
            title: 'Wallpaper selection',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Wallpaper selection')),
              );
            },
          ),
          _buildSectionTitle('Notifications'),
          _buildToggleSettingsTile(
            context,
            icon: Icons.message_outlined,
            title: 'Message notifications',
            value: _messageNotifications,
            onChanged: (newValue) {
              setState(() {
                _messageNotifications = newValue;
              });
              // TODO: Implement message notifications toggle logic
            },
          ),
          _buildToggleSettingsTile(
            context,
            icon: Icons.groups_outlined,
            title: 'Group notifications',
            value: _groupNotifications,
            onChanged: (newValue) {
              setState(() {
                _groupNotifications = newValue;
              });
              // TODO: Implement group notifications toggle logic
            },
          ),
          _buildToggleSettingsTile(
            context,
            icon: Icons.call_outlined,
            title: 'Call notifications',
            value: _callNotifications,
            onChanged: (newValue) {
              setState(() {
                _callNotifications = newValue;
              });
              // TODO: Implement call notifications toggle logic
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.music_note_outlined,
            title: 'Notification tone',
            trailing: Text(_notificationTone),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select Notification Tone')),
              );
              // TODO: Implement notification tone selection
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.vibration_outlined,
            title: 'Vibration',
            value: _vibration,
            items: const ['Off', 'Default', 'Short', 'Long'],
            onChanged: (newValue) {
              setState(() {
                _vibration = newValue!;
              });
              // TODO: Implement vibration setting logic
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Popup notification',
            value: _popupNotification,
            items: const ['Always', 'Only when screen is on', 'Off'],
            onChanged: (newValue) {
              setState(() {
                _popupNotification = newValue!;
              });
              // TODO: Implement popup notification logic
            },
          ),
          _buildSectionTitle('Privacy'),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.visibility_outlined,
            title: 'Last seen & Online',
            value: _lastSeenVisibility,
            items: const ['Everyone', 'Contacts', 'Nobody'],
            onChanged: (newValue) {
              setState(() {
                _lastSeenVisibility = newValue!;
              });
              // TODO: Implement last seen visibility logic
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.photo_outlined,
            title: 'Profile photo visibility',
            value: _profilePhotoVisibility,
            items: const ['Everyone', 'Contacts', 'Nobody'],
            onChanged: (newValue) {
              setState(() {
                _profilePhotoVisibility = newValue!;
              });
              // TODO: Implement profile photo visibility logic
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'About visibility',
            value: _aboutVisibility,
            items: const ['Everyone', 'Contacts', 'Nobody'],
            onChanged: (newValue) {
              setState(() {
                _aboutVisibility = newValue!;
              });
              // TODO: Implement about visibility logic
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.radio_button_checked, // Changed icon
            title: 'Status',
            value: _statusVisibility,
            items: const ['All', 'Contacts', 'Except...'],
            onChanged: (newValue) {
              setState(() {
                _statusVisibility = newValue!;
              });
              // TODO: Implement status visibility logic
            },
          ),
          _buildToggleSettingsTile(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Read receipts',
            value: _readReceipts,
            onChanged: (newValue) {
              setState(() {
                _readReceipts = newValue;
              });
              // TODO: Implement read receipts toggle logic
            },
          ),
          _buildDropdownSettingsTile(
            context,
            icon: Icons.timer_outlined,
            title: 'Disappearing messages',
            value: _disappearingMessages,
            items: const ['24 hours', '7 days', 'Off'],
            onChanged: (newValue) {
              setState(() {
                _disappearingMessages = newValue!;
              });
              // TODO: Implement disappearing messages logic
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.block_outlined,
            title: 'Blocked contacts list',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Blocked contacts list')),
              );
              // TODO: Implement navigation to blocked contacts list
            },
          ),
          _buildSectionTitle('Security'),
          _buildToggleSettingsTile(
            context,
            icon: Icons.fingerprint_outlined,
            title: 'Fingerprint lock',
            value: _fingerprintLock,
            onChanged: (newValue) {
              setState(() {
                _fingerprintLock = newValue;
              });
              // TODO: Implement fingerprint lock logic
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            title: 'End-to-End encryption info',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Show End-to-End encryption info')),
              );
              // TODO: Implement end-to-end encryption info display
            },
          ),
          _buildSectionTitle('Help'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'FAQ / Contact support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to FAQ / Contact support')),
              );
              // TODO: Implement navigation to FAQ/Contact support
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'App info',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Show App info')),
              );
              // TODO: Implement app info display
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.policy_outlined,
            title: 'Terms & Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Terms & Privacy Policy')),
              );
              // TODO: Implement navigation to terms & privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildToggleSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDropdownSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
