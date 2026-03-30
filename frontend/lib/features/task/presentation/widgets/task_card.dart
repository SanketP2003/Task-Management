import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.searchQuery = '',
    this.onTap,
  });

  final TaskEntity task;
  final String searchQuery;
  final VoidCallback? onTap;

  bool _isBlocked(WidgetRef ref) {
    if (task.blockedBy == null) return false;

    final allTasks = ref.watch(allTasksProvider).valueOrNull ?? <TaskEntity>[];
    final blockingTask =
        allTasks.where((t) => t.id == task.blockedBy).firstOrNull;

    if (blockingTask != null) {
      return blockingTask.status != TaskStatus.done;
    }

    return task.status != TaskStatus.done;
  }

  Widget _buildHighlightedText(
      String text, String query, BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    if (query.trim().isEmpty) {
      return Text(
        text,
        style: titleStyle,
      );
    }

    final matchIndex = text.toLowerCase().indexOf(query.toLowerCase());
    if (matchIndex == -1) {
      return Text(
        text,
        style: titleStyle,
      );
    }

    final beforeMatch = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + query.length);
    final afterMatch = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: titleStyle,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: TextStyle(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateText = DateFormat('MMM d, yyyy').format(task.dueDate);

    final statusStyle = _statusStyle(task.status, colorScheme, theme);
    final isBlocked = _isBlocked(ref);
    final isOverdue =
        task.status != TaskStatus.done && task.dueDate.isBefore(DateTime.now());
    final leftAccent = switch (task.status) {
      TaskStatus.todo => const Color(0xFFB0BEC5),
      TaskStatus.inProgress => const Color(0xFFF5B301),
      TaskStatus.done => const Color(0xFF18B28C),
    };

    return AbsorbPointer(
      absorbing: isBlocked,
      child: Opacity(
        opacity: isBlocked ? 0.5 : 1,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          color: isBlocked
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surface,
          child: InkWell(
            onTap: isBlocked ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: leftAccent, width: 4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHighlightedText(
                                  task.title, searchQuery, context),
                              const SizedBox(height: 6),
                              Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            final scale = Tween<double>(begin: 0.92, end: 1)
                                .animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child:
                                  ScaleTransition(scale: scale, child: child),
                            );
                          },
                          child: _StatusBadge(
                            key: ValueKey(statusStyle.label),
                            style: statusStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.event,
                          label: dateText,
                          color: isOverdue
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                        if (isOverdue)
                          _InfoChip(
                            icon: Icons.warning_amber_rounded,
                            label: 'Overdue',
                            color: colorScheme.error,
                          ),
                        if (isBlocked)
                          _InfoChip(
                            icon: Icons.block,
                            label: 'Blocked by #${task.blockedBy}',
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(
      TaskStatus status, ColorScheme colorScheme, ThemeData theme) {
    switch (status) {
      case TaskStatus.todo:
        return const _StatusStyle(
          label: 'To-Do',
          background: Color(0xFFE0E0E0),
          foreground: Color(0xFF424242),
        );
      case TaskStatus.inProgress:
        return const _StatusStyle(
          label: 'In Progress',
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFE65100),
        );
      case TaskStatus.done:
        return const _StatusStyle(
          label: 'Done',
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        );
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    super.key,
    required this.style,
  });

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
