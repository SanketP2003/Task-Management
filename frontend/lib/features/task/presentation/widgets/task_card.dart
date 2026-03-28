import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  final TaskEntity task;
  final VoidCallback? onTap;

  bool _isBlocked(WidgetRef ref) {
    if (task.blockedBy == null) return false;

    final allTasks = ref.watch(allTasksProvider).valueOrNull ?? <TaskEntity>[];
    final blockingTask =
        allTasks.where((t) => t.id == task.blockedBy).firstOrNull;

    // Task is disabled ONLY if the blocked task is not "Done".
    if (blockingTask != null) {
      return blockingTask.status != TaskStatus.done;
    }

    // Fallback if not found (maybe assume not blocked or still blocked depending on UX)
    return task.status != TaskStatus.done; // Just keep old logic as fallback
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateText = DateFormat('MMM d, yyyy').format(task.dueDate);

    final statusStyle = _statusStyle(task.status, colorScheme, theme);
    final isBlocked = _isBlocked(ref);

    return AbsorbPointer(
      absorbing: isBlocked,
      child: Opacity(
        opacity: isBlocked ? 0.5 : 1,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          color: isBlocked
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surface,
          child: InkWell(
            onTap: isBlocked ? null : onTap,
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
                            Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(style: statusStyle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isBlocked) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.block,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Blocked by #${task.blockedBy}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
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
        return _StatusStyle(
          label: 'To-Do',
          background: colorScheme.secondaryContainer,
          foreground: colorScheme.onSecondaryContainer,
        );
      case TaskStatus.inProgress:
        return _StatusStyle(
          label: 'In Progress',
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
        );
      case TaskStatus.done:
        return _StatusStyle(
          label: 'Done',
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
