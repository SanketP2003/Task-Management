import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _debounce;
  bool _isFabExpanded = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(taskSearchQueryProvider),
    );
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _isFabExpanded) {
      setState(() => _isFabExpanded = false);
    } else if (direction == ScrollDirection.forward && !_isFabExpanded) {
      setState(() => _isFabExpanded = true);
    }
  }

  void _onSearchChanged(String value) {
    ref.read(taskSearchQueryProvider.notifier).state = value;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(taskProvider.notifier).refresh();
    });
  }

  void _onStatusChanged(TaskStatus? value) {
    ref.read(taskStatusFilterProvider.notifier).state = value;
    ref.read(taskProvider.notifier).refresh();
  }

  void _cycleSortMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Advanced sorting coming soon')),
    );
  }

  String _statusLabel(TaskStatus? status) {
    switch (status) {
      case null:
        return 'All';
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(taskProvider, (previous, next) {
      if (next.hasError && !next.isLoading && previous?.hasValue == true) {
        final rawError = next.error.toString();
        String errorMessage = 'Something went wrong';

        if (rawError.contains('Network error') ||
            rawError.contains('SocketException') ||
            rawError.contains('timed out')) {
          errorMessage = 'Network error';
        } else if (rawError.contains('Failed to load') ||
            next.error is StateError) {
          errorMessage = 'Failed to load tasks';
        } else {
          errorMessage = rawError.startsWith('Exception: ')
              ? rawError.substring(11)
              : rawError;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => ref.read(taskProvider.notifier).refresh(),
              ),
            ),
          );
        }
      }
    });

    final tasksAsync = ref.watch(taskProvider);
    final selectedStatus = ref.watch(taskStatusFilterProvider);
    final searchQuery = ref.watch(taskSearchQueryProvider);
    final hasFilters = selectedStatus != null || searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear search',
                          ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: selectedStatus == null,
                              onTap: () => _onStatusChanged(null),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'To-Do',
                              selected: selectedStatus == TaskStatus.todo,
                              onTap: () => _onStatusChanged(TaskStatus.todo),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'In Progress',
                              selected: selectedStatus == TaskStatus.inProgress,
                              onTap: () =>
                                  _onStatusChanged(TaskStatus.inProgress),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Done',
                              selected: selectedStatus == TaskStatus.done,
                              onTap: () => _onStatusChanged(TaskStatus.done),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Sort',
                      onPressed: () => _cycleSortMessage(context),
                      icon: const Icon(Icons.sort_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing: ${_statusLabel(selectedStatus)} ${searchQuery.trim().isEmpty ? '' : '• "$searchQuery"'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(taskProvider.notifier).refresh(),
              child: tasksAsync.when(
                skipError: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, __) {
                  String errorMessage = error.toString();
                  if (errorMessage.contains('Network') ||
                      errorMessage.contains('Socket') ||
                      errorMessage.contains('timed out')) {
                    errorMessage =
                        'Network error: Please check your connection.';
                  } else if (errorMessage.startsWith('Exception: ')) {
                    errorMessage = errorMessage.replaceFirst('Exception: ', '');
                  }
                  if (errorMessage.length > 100) {
                    errorMessage = 'Failed to load tasks';
                  }

                  return _ErrorState(
                    message: errorMessage,
                    onRetry: () => ref.read(taskProvider.notifier).refresh(),
                  );
                },
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _EmptyState(hasFilters: hasFilters);
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ListView.separated(
                      controller: _scrollController,
                      key: ValueKey(tasks.length),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 180 + (index * 28)),
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 16),
                                child: child,
                              ),
                            );
                          },
                          child: Dismissible(
                            key: ValueKey(task.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                            onDismissed: (_) {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(taskProvider.notifier)
                                  .deleteTask(task.id)
                                  .then((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Task deleted')),
                                  );
                                }
                              }).catchError((error) {
                                if (context.mounted) {
                                  String msg = error.toString();
                                  if (msg.contains('Network') ||
                                      msg.contains('Socket') ||
                                      msg.contains('time')) {
                                    msg = 'Network error';
                                  } else if (msg.startsWith('Exception: ')) {
                                    msg = msg.substring(11);
                                  } else if (msg.length > 50) {
                                    msg = 'Something went wrong';
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Failed to delete task: $msg'),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  ref.read(taskProvider.notifier).refresh();
                                }
                              });
                            },
                            child: TaskCard(
                              task: task,
                              searchQuery: searchQuery,
                              onTap: () => Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      TaskFormScreen(task: task),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOut;
                                    final tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child);
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: tasks.length,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: _isFabExpanded
            ? FloatingActionButton.extended(
                key: const ValueKey('fab_extended'),
                tooltip: 'Add Task',
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const TaskFormScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutQuart;
                      final tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      final slideAnimation = animation.drive(tween);
                      return SlideTransition(
                          position: slideAnimation, child: child);
                    },
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
                elevation: 4,
              )
            : FloatingActionButton(
                key: const ValueKey('fab_compact'),
                tooltip: 'Add Task',
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const TaskFormScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutQuart;
                      final tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      final slideAnimation = animation.drive(tween);
                      return SlideTransition(
                          position: slideAnimation, child: child);
                    },
                  ),
                ),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.hasFilters = false,
  });

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFilters ? Icons.search_off_rounded : Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  hasFilters ? 'No matching tasks found.' : 'No tasks yet.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!hasFilters) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to add a new task.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.14)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
