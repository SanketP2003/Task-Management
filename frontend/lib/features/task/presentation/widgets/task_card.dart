import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';

class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.searchQuery = '',
    this.onTap,
  });

  final TaskEntity task;
  final String searchQuery;
  final VoidCallback? onTap;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  late final TextEditingController _subtaskController;
  bool _isExpanded = false;
  bool _isSubmittingSubtask = false;

  @override
  void initState() {
    super.initState();
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _subtaskController.dispose();
    super.dispose();
  }

  bool _isBlocked(WidgetRef ref) {
    if (widget.task.blockedBy == null) return false;

    final allTasks = ref.watch(allTasksProvider).valueOrNull ?? <TaskEntity>[];
    final blockingTask =
        allTasks.where((t) => t.id == widget.task.blockedBy).firstOrNull;

    if (blockingTask != null) {
      return blockingTask.status != TaskStatus.done;
    }

    return widget.task.status != TaskStatus.done;
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
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateText = DateFormat('MMM d, yyyy').format(widget.task.dueDate);

    final statusStyle = _statusStyle(widget.task.status, colorScheme, theme);
    final isBlocked = _isBlocked(ref);
    final isOverdue = widget.task.status != TaskStatus.done &&
        widget.task.dueDate.isBefore(DateTime.now());
    final leftAccent = switch (widget.task.status) {
      TaskStatus.todo => const Color(0xFFB0BEC5),
      TaskStatus.inProgress => const Color(0xFFF5B301),
      TaskStatus.done => const Color(0xFF18B28C),
    };

    final subtasks = widget.task.subtasks;
    final completedSubtasks =
        subtasks.where((subtask) => subtask.isCompleted).length;

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
            onTap: isBlocked ? null : widget.onTap,
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
                              _buildHighlightedText(widget.task.title,
                                  widget.searchQuery, context),
                              const SizedBox(height: 6),
                              Text(
                                widget.task.description,
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
                            label: 'Blocked by #${widget.task.blockedBy}',
                            color: colorScheme.error,
                          ),
                        if (widget.task.category != null)
                          _InfoChip(
                            icon: Icons.label_outline,
                            label: widget.task.category!.name,
                            color: colorScheme.tertiary,
                          ),
                        if (subtasks.isNotEmpty)
                          _InfoChip(
                            icon: Icons.playlist_add_check,
                            label:
                                '$completedSubtasks/${subtasks.length} subtasks',
                            color: colorScheme.secondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        maintainState: true,
                        initiallyExpanded: _isExpanded,
                        onExpansionChanged: (value) {
                          setState(() => _isExpanded = value);
                        },
                        title: Text(
                          'Subtasks',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          if (subtasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'No subtasks yet',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          for (final subtask in subtasks)
                            Row(
                              children: [
                                Checkbox(
                                  value: subtask.isCompleted,
                                  onChanged: (value) async {
                                    if (value == null) {
                                      return;
                                    }
                                    try {
                                      await ref
                                          .read(taskProvider.notifier)
                                          .toggleSubtask(
                                            taskId: widget.task.id,
                                            subtaskId: subtask.id,
                                            isCompleted: value,
                                          );
                                    } catch (error) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content: Text(error.toString())),
                                      );
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      decoration: subtask.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(taskProvider.notifier)
                                          .deleteSubtask(
                                            taskId: widget.task.id,
                                            subtaskId: subtask.id,
                                          );
                                    } catch (error) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content: Text(error.toString())),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _subtaskController,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) async {
                                    if (_isSubmittingSubtask) {
                                      return;
                                    }
                                    final value =
                                        _subtaskController.text.trim();
                                    if (value.isEmpty) {
                                      return;
                                    }
                                    setState(() => _isSubmittingSubtask = true);
                                    try {
                                      await ref
                                          .read(taskProvider.notifier)
                                          .addSubtask(
                                            taskId: widget.task.id,
                                            title: value,
                                          );
                                      _subtaskController.clear();
                                    } catch (error) {
                                      if (!context.mounted) {
                                        return;
                                      }
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      messenger.showSnackBar(
                                        SnackBar(
                                            content: Text(error.toString())),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(
                                            () => _isSubmittingSubtask = false);
                                      }
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Add subtask',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: _isSubmittingSubtask
                                    ? null
                                    : () async {
                                        final value =
                                            _subtaskController.text.trim();
                                        if (value.isEmpty) {
                                          return;
                                        }
                                        setState(
                                            () => _isSubmittingSubtask = true);
                                        try {
                                          await ref
                                              .read(taskProvider.notifier)
                                              .addSubtask(
                                                taskId: widget.task.id,
                                                title: value,
                                              );
                                          _subtaskController.clear();
                                        } catch (error) {
                                          if (!context.mounted) {
                                            return;
                                          }
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          messenger.showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text(error.toString())),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() =>
                                                _isSubmittingSubtask = false);
                                          }
                                        }
                                      },
                                icon: _isSubmittingSubtask
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
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
