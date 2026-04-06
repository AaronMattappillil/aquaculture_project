import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Header
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF112236),
                  child: Icon(Icons.person, size: 50, color: Color(0xFF0E6E8A)),
                ),
                const SizedBox(height: 16),
                Text(
                  '${user?.firstName ?? 'Farmer'} ${user?.lastName ?? 'User'}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? 'john@aqua.com',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E6E8A).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? 'FARMER',
                    style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          const Text('ACCOUNT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _buildListTile(Icons.person_outline, 'Profile Information', 'Manage your name and contact details', () {
            context.push('/manage-profile');
          }),
          _buildListTile(Icons.notifications_none, 'Notification Settings', 'Configure alerts and push notifications', () {
             context.push('/notification-settings');
          }),
          
          const SizedBox(height: 24),
          const Text('SUPPORT & ABOUT', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          _buildListTile(Icons.help_outline, 'Help & FAQ', 'Common questions and support guides', () {
             context.push('/help-faq');
          }),
          _buildListTile(Icons.info_outline, 'About AquaSense', 'App version, terms, and privacy policy', () {
             context.push('/about-aquasense');
          }),
          
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authStateProvider.notifier).state = null;
              // Go router will automatically redirect to login because of the listener in app.dart
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF112236),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF0E6E8A), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}
