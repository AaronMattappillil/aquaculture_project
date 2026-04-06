import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationsProvider = StateProvider<bool>((ref) => true);
final alertNotificationsProvider = StateProvider<bool>((ref) => true);

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushNotifications = ref.watch(pushNotificationsProvider);
    final alertNotifications = ref.watch(alertNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            context,
            'Push Notifications',
            'Receive push notifications for app updates',
            pushNotifications,
            (value) => ref.read(pushNotificationsProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            context,
            'Alert Notifications',
            'Receive alerts for critical pond conditions',
            alertNotifications,
            (value) => ref.read(alertNotificationsProvider.notifier).state = value,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved locally')),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E6E8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF112236),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF0E6E8A),
      ),
    );
  }
}
