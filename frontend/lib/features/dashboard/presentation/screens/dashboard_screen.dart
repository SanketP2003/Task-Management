import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../task/presentation/providers/task_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: tasksAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Failed to load dashboard\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (tasks) {
          final now = DateTime.now();
          final today = tasks.where((t) {
            final d = t.dueDate;
            return d.year == now.year &&
                d.month == now.month &&
                d.day == now.day;
          }).toList(growable: false);
          final upcoming = tasks
              .where((t) => t.dueDate.isAfter(now))
              .toList(growable: false);
          final completed = tasks
              .where((t) => t.status.name == 'done')
              .toList(growable: false);
          final progress =
              tasks.isEmpty ? 0.0 : completed.length / tasks.length;

          final pending = tasks.length - completed.length;

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 14),
                  child: child,
                ),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Today at a glance',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Stay focused and finish what matters most.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E6CF6), Color(0xFF5CC8A1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Productivity',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).round()}% complete',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _MetricPill(label: 'Pending', value: pending),
                          const SizedBox(width: 8),
                          _MetricPill(label: 'Done', value: completed.length),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'Today'),
                const SizedBox(height: 8),
                _SummaryTile(label: 'Due today', count: today.length),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Upcoming'),
                const SizedBox(height: 8),
                _SummaryTile(label: 'Planned next', count: upcoming.length),
                const SizedBox(height: 16),
                const _SectionHeader(title: 'Completed'),
                const SizedBox(height: 8),
                _SummaryTile(label: 'Finished tasks', count: completed.length),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pending == 0
                        ? 'You are all caught up. Great job!'
                        : 'You have $pending pending task${pending == 1 ? '' : 's'} to focus on next.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: const Text('Tap Tasks tab to manage items'),
        trailing: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text('$count'),
        ),
      ),
    );
  }
}
