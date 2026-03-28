import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/task_entity.dart';
import '../providers/task_provider.dart';

final taskFormProvider =
    NotifierProvider.family<TaskFormNotifier, TaskFormState, String>(
  TaskFormNotifier.new,
);

enum TaskFormSubmissionStatus {
  idle,
  loading,
  success,
  error,
}

class TaskFormState {
  const TaskFormState({
    this.initialized = false,
    this.editingTaskId,
    this.title = '',
    this.description = '',
    this.dueDate,
    this.status = TaskStatus.todo,
    this.blockedBy,
    this.submissionStatus = TaskFormSubmissionStatus.idle,
    this.errorMessage,
  });

  final bool initialized;
  final int? editingTaskId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskStatus status;
  final int? blockedBy;
  final TaskFormSubmissionStatus submissionStatus;
  final String? errorMessage;

  bool get isEditMode => editingTaskId != null;
  bool get isLoading => submissionStatus == TaskFormSubmissionStatus.loading;

  TaskFormState copyWith({
    bool? initialized,
    int? editingTaskId,
    bool keepEditingTaskId = true,
    String? title,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskStatus? status,
    int? blockedBy,
    bool clearBlockedBy = false,
    TaskFormSubmissionStatus? submissionStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TaskFormState(
      initialized: initialized ?? this.initialized,
      editingTaskId: keepEditingTaskId
          ? (editingTaskId ?? this.editingTaskId)
          : editingTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      blockedBy: clearBlockedBy ? null : (blockedBy ?? this.blockedBy),
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TaskFormNotifier extends FamilyNotifier<TaskFormState, String> {
  @override
  TaskFormState build(String arg) {
    return const TaskFormState();
  }

  void initialize(TaskEntity? task) {
    if (state.initialized) {
      return;
    }

    if (task == null) {
      state = state.copyWith(initialized: true, clearErrorMessage: true);
      return;
    }

    state = state.copyWith(
      initialized: true,
      editingTaskId: task.id,
      keepEditingTaskId: false,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      status: task.status,
      blockedBy: task.blockedBy,
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  void setTitle(String value) {
    state = state.copyWith(
      title: value,
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  void setDescription(String value) {
    state = state.copyWith(
      description: value,
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  void setDueDate(DateTime? value) {
    if (value == null) {
      state = state.copyWith(
        clearDueDate: true,
        submissionStatus: TaskFormSubmissionStatus.idle,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      dueDate: DateTime(value.year, value.month, value.day),
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  void setStatus(TaskStatus value) {
    state = state.copyWith(
      status: value,
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  void setBlockedBy(int? value) {
    if (value == null) {
      state = state.copyWith(
        clearBlockedBy: true,
        submissionStatus: TaskFormSubmissionStatus.idle,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      blockedBy: value,
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  Future<bool> submit() async {
    final validationMessage = _validate();
    if (validationMessage != null) {
      state = state.copyWith(
        submissionStatus: TaskFormSubmissionStatus.error,
        errorMessage: validationMessage,
      );
      return false;
    }

    final repository = ref.read(taskRepositoryProvider);

    state = state.copyWith(
      submissionStatus: TaskFormSubmissionStatus.loading,
      clearErrorMessage: true,
    );

    try {
      if (state.isEditMode) {
        await repository.updateTask(
          id: state.editingTaskId!,
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate!,
          status: state.status,
          blockedBy: state.blockedBy,
          setBlockedBy: true,
        );
      } else {
        await repository.createTask(
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate!,
          status: state.status,
          blockedBy: state.blockedBy,
        );
      }

      ref.invalidate(taskProvider);

      state = state.copyWith(
        submissionStatus: TaskFormSubmissionStatus.success,
        clearErrorMessage: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        submissionStatus: TaskFormSubmissionStatus.error,
        errorMessage: _readableError(error),
      );
      return false;
    }
  }

  String? _validate() {
    if (state.title.trim().isEmpty) {
      return 'Title is required.';
    }

    if (state.dueDate == null) {
      return 'Due date is required.';
    }

    if (state.editingTaskId != null && state.blockedBy == state.editingTaskId) {
      return 'A task cannot be blocked by itself.';
    }

    return null;
  }

  String _readableError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}

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
    notifier.initialize(widget.task);

    final formState = ref.read(taskFormProvider(_draftKey));

    _titleController = TextEditingController(text: formState.title);
    _descriptionController = TextEditingController(text: formState.description);
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success =
        await ref.read(taskFormProvider(_draftKey).notifier).submit();

    if (!mounted) {
      return;
    }

    final formState = ref.read(taskFormProvider(_draftKey));

    if (success) {
      final actionText = _isEditMode ? 'Task updated' : 'Task created';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(actionText)),
      );
      Navigator.of(context).pop(true);
      return;
    }

    if (formState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formState.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(taskFormProvider(_draftKey));
    final tasksAsync = ref.watch(taskProvider);
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
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: formState.isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !formState.isLoading,
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
                    enabled: !formState.isLoading,
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
                        onTap: formState.isLoading
                            ? null
                            : () => _pickDueDate(formState),
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
                    onChanged: formState.isLoading
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
                    onChanged: formState.isLoading
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
                      onPressed: formState.isLoading ||
                              formState.blockedBy == null
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
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: formState.isLoading ? null : _submit,
                      child: formState.isLoading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Saving...'),
                              ],
                            )
                          : Text(_isEditMode ? 'Update Task' : 'Create Task'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
