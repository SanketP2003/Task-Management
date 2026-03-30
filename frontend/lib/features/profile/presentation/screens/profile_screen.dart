import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    final themeMode = ref.watch(themeProvider).valueOrNull ?? ThemeMode.light;
    final notificationsEnabled =
        ref.watch(notificationSettingsProvider).valueOrNull ?? true;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Account',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session?.email ?? 'Unknown user',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile.adaptive(
              value: isDarkMode,
              onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
              secondary: const Icon(Icons.palette_outlined),
              title: const Text('Dark Mode'),
              subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
            ),
          ),
          Card(
            child: SwitchListTile.adaptive(
              value: notificationsEnabled,
              onChanged: (value) => ref
                  .read(notificationSettingsProvider.notifier)
                  .setEnabled(value),
              secondary: const Icon(Icons.notifications_none),
              title: const Text('Notifications'),
              subtitle: Text(
                notificationsEnabled ? 'Enabled' : 'Disabled',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
