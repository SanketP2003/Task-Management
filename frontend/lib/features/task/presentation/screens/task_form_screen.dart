import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({
    super.key,
    this.task,
  });

  final TaskEntity? task;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormatter = DateFormat('MMM d, yyyy');

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String get _draftKey =>
      widget.task == null ? 'new' : 'edit_${widget.task!.id}';

  bool get _isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();

    final notifier = ref.read(taskFormProvider(_draftKey).notifier);
    final formState = ref.read(taskFormProvider(_draftKey));

    if (!formState.initialized) {
      Future.microtask(() => notifier.initialize(widget.task));
      _titleController = TextEditingController(text: widget.task?.title ?? '');
      _descriptionController =
          TextEditingController(text: widget.task?.description ?? '');
    } else {
      _titleController = TextEditingController(text: formState.title);
      _descriptionController =
          TextEditingController(text: formState.description);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(TaskFormState formState) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 10);
    final initialDate = formState.dueDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? now : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      ref.read(taskFormProvider(_draftKey).notifier).setDueDate(picked);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formState = ref.read(taskFormProvider(_draftKey));
    final isMutating = ref.read(taskMutationLoadingProvider);
    if (formState.isLoading || isMutating) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success =
        await ref.read(taskFormProvider(_draftKey).notifier).submit();

    if (!mounted) {
      return;
    }

    final latestFormState = ref.read(taskFormProvider(_draftKey));

    if (success) {
      final actionText = _isEditMode ? 'Task updated' : 'Task created';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(actionText)),
      );
      Navigator.of(context).pop(true);
      return;
    }

    if (latestFormState.errorMessage != null) {
      String msg = latestFormState.errorMessage!;
      if (msg.contains('Network') ||
          msg.contains('Socket') ||
          msg.contains('time')) {
        msg = 'Network error';
      } else if (msg.length > 80 && !msg.contains(' ')) {
        msg = 'Something went wrong';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(taskFormProvider(_draftKey));
    final isMutating = ref.watch(taskMutationLoadingProvider);
    final isLoading = formState.isLoading || isMutating;
    final tasksAsync = ref.watch(allTasksProvider);
    final allTasks = tasksAsync.valueOrNull ?? <TaskEntity>[];

    final candidateTasks = allTasks
        .where((task) => !_isEditMode || task.id != widget.task!.id)
        .toList(growable: false);

    final taskTitlesById = <int, String>{
      for (final task in candidateTasks) task.id: task.title,
    };

    final selectedBlockedBy = formState.blockedBy;
    final hasMissingSelectedTask = selectedBlockedBy != null &&
        !taskTitlesById.containsKey(selectedBlockedBy);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'Create Task'),
        bottom: isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter a task title',
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => ref
                        .read(taskFormProvider(_draftKey).notifier)
                        .setTitle(value),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Add details for this task',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    onChanged: (value) => ref
                        .read(taskFormProvider(_draftKey).notifier)
                        .setDescription(value),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Schedule',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 16),
                  FormField<DateTime>(
                    validator: (_) {
                      if (formState.dueDate == null) {
                        return 'Due date is required';
                      }
                      return null;
                    },
                    builder: (field) {
                      final dueDateText = formState.dueDate == null
                          ? 'Select a due date'
                          : _dateFormatter.format(formState.dueDate!);

                      return InkWell(
                        onTap: isLoading ? null : () => _pickDueDate(formState),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Due Date',
                            errorText: field.errorText,
                            suffixIcon:
                                const Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(dueDateText),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status & Dependency',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TaskStatus>(
                    initialValue: formState.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      hintText: 'Select status',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TaskStatus.todo,
                        child: Text('To-Do'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatus.inProgress,
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatus.done,
                        child: Text('Done'),
                      ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              ref
                                  .read(taskFormProvider(_draftKey).notifier)
                                  .setStatus(value);
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedBlockedBy,
                    decoration: const InputDecoration(
                      labelText: 'Blocked By',
                      hintText: 'Select blocking task',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...candidateTasks.map(
                        (task) => DropdownMenuItem<int?>(
                          value: task.id,
                          child: Text('#${task.id} - ${task.title}'),
                        ),
                      ),
                      if (hasMissingSelectedTask)
                        DropdownMenuItem<int?>(
                          value: selectedBlockedBy,
                          child: Text('Task #$selectedBlockedBy (unavailable)'),
                        ),
                    ],
                    onChanged: isLoading
                        ? null
                        : (value) {
                            ref
                                .read(taskFormProvider(_draftKey).notifier)
                                .setBlockedBy(value);
                            _formKey.currentState?.validate();
                          },
                    validator: (_) {
                      if (_isEditMode && selectedBlockedBy == widget.task!.id) {
                        return 'Task cannot be blocked by itself';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading || formState.blockedBy == null
                          ? null
                          : () {
                              ref
                                  .read(taskFormProvider(_draftKey).notifier)
                                  .setBlockedBy(null);
                              _formKey.currentState?.validate();
                            },
                      child: const Text('Clear selection'),
                    ),
                  ),
                  if (formState.submissionStatus ==
                          TaskFormSubmissionStatus.error &&
                      formState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        formState.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Saving...'),
                    ],
                  )
                : Text(_isEditMode ? 'Save Changes' : 'Create Task'),
          ),
        ),
      ),
    );
  }
}
