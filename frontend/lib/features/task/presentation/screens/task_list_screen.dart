import 'dart:async';

import 'package:flutter/material.dart';
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(taskSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
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
    final tasksAsync = ref.watch(taskProvider);
    final selectedStatus = ref.watch(taskStatusFilterProvider);
    final searchQuery = ref.watch(taskSearchQueryProvider);
    final hasFilters = selectedStatus != null || searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TaskStatus?>(
                      value: selectedStatus,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: _onStatusChanged,
                      items: const [
                        DropdownMenuItem<TaskStatus?>(
                          value: null,
                          child: Text('All'),
                        ),
                        DropdownMenuItem<TaskStatus?>(
                          value: TaskStatus.todo,
                          child: Text('To-Do'),
                        ),
                        DropdownMenuItem<TaskStatus?>(
                          value: TaskStatus.inProgress,
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem<TaskStatus?>(
                          value: TaskStatus.done,
                          child: Text('Done'),
                        ),
                      ],
                    ),
                  ),
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
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, __) => _ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.read(taskProvider.notifier).refresh(),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _EmptyState(hasFilters: hasFilters);
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ListView.separated(
                      key: ValueKey(tasks.length),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Dismissible(
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
                            ref
                                .read(taskProvider.notifier)
                                .deleteTask(task.id)
                                .then((_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Task deleted')),
                                );
                              }
                            }).catchError((error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Failed to delete task: \${error.toString()}')),
                                );
                                ref
                                    .read(taskProvider.notifier)
                                    .refresh(); // restore UI
                              }
                            });
                          },
                          child: TaskCard(
                            task: task,
                            onTap: () => Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
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
      floatingActionButton: FloatingActionButton.extended(
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
              final tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              final slideAnimation = animation.drive(tween);
              return SlideTransition(position: slideAnimation, child: child);
            },
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        elevation: 4,
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
