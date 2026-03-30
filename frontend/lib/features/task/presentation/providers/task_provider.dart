import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';

const _baseUrl = 'http://localhost:8000/api/v1';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authState = ref.watch(authProvider).valueOrNull;
  return ApiClient(
    baseUrl: _baseUrl,
    tokenProvider: () => authState?.accessToken,
  );
});

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TaskRemoteDataSource(apiClient);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteDataSource = ref.watch(taskRemoteDataSourceProvider);
  return TaskRepositoryImpl(remoteDataSource);
});

final taskSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

final taskStatusFilterProvider = StateProvider<TaskStatus?>((ref) {
  return null;
});

final taskCategoryFilterProvider = StateProvider<int?>((ref) {
  return null;
});

final taskMutationLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

final taskProvider =
    AsyncNotifierProvider<TaskNotifier, List<TaskEntity>>(TaskNotifier.new);

final allTasksProvider =
    AsyncNotifierProvider<AllTasksNotifier, List<TaskEntity>>(
        AllTasksNotifier.new);

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryEntity>>(
        CategoryNotifier.new);

class CategoryNotifier extends AsyncNotifier<List<CategoryEntity>> {
  @override
  Future<List<CategoryEntity>> build() async {
    return ref.read(taskRepositoryProvider).fetchCategories();
  }

  Future<void> refresh() async {
    if (state.hasValue) {
      state =
          AsyncValue<List<CategoryEntity>>.loading().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final categories =
          await ref.read(taskRepositoryProvider).fetchCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      if (state.hasValue) {
        state = AsyncValue<List<CategoryEntity>>.error(e, st)
            .copyWithPrevious(state);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

class AllTasksNotifier extends AsyncNotifier<List<TaskEntity>> {
  Future<T> _withAuthGuard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        throw Exception('Session expired. Please log in again.');
      }
      rethrow;
    }
  }

  @override
  Future<List<TaskEntity>> build() async {
    return _withAuthGuard(() => ref.read(taskRepositoryProvider).fetchTasks());
  }

  Future<void> refresh() async {
    if (state.hasValue) {
      state = AsyncValue<List<TaskEntity>>.loading().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _withAuthGuard(
        () => ref.read(taskRepositoryProvider).fetchTasks(),
      );
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state.hasValue) {
        state =
            AsyncValue<List<TaskEntity>>.error(e, st).copyWithPrevious(state);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

class TaskNotifier extends AsyncNotifier<List<TaskEntity>> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  Future<void> _notifyIfEnabled(Future<void> Function() action) async {
    final enabled = ref.read(notificationSettingsProvider).valueOrNull ?? true;
    if (!enabled) {
      return;
    }
    await action();
  }

  Future<T> _withAuthGuard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        throw Exception('Session expired. Please log in again.');
      }
      rethrow;
    }
  }

  String get _searchQuery {
    final value = ref.read(taskSearchQueryProvider).trim();
    return value;
  }

  TaskStatus? get _selectedStatus => ref.read(taskStatusFilterProvider);

  int? get _selectedCategoryId => ref.read(taskCategoryFilterProvider);

  @override
  Future<List<TaskEntity>> build() async {
    return _withAuthGuard(
      () => _repository.fetchTasks(
        status: _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
      ),
    );
  }

  Future<void> refresh() async {
    if (state.hasValue) {
      state = AsyncValue<List<TaskEntity>>.loading().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _withAuthGuard(
        () => _repository.fetchTasks(
          status: _selectedStatus,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          categoryId: _selectedCategoryId,
        ),
      );
      state = AsyncValue.data(data);
    } catch (e, st) {
      if (state.hasValue) {
        state =
            AsyncValue<List<TaskEntity>>.error(e, st).copyWithPrevious(state);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
    int? categoryId,
  }) async {
    if (ref.read(taskMutationLoadingProvider)) {
      return;
    }

    ref.read(taskMutationLoadingProvider.notifier).state = true;

    final previous = state.valueOrNull ?? <TaskEntity>[];

    try {
      final created = await _withAuthGuard(
        () => _repository.createTask(
          title: title,
          description: description,
          dueDate: dueDate,
          status: status,
          blockedBy: blockedBy,
          categoryId: categoryId,
        ),
      );

      state = AsyncValue.data([created, ...previous]);
      await _notifyIfEnabled(
        () => NotificationService.instance.showTaskCreated(created.title),
      );
      await _notifyIfEnabled(
        () => NotificationService.instance.scheduleTaskReminder(
          taskId: created.id,
          title: created.title,
          dueDate: created.dueDate,
        ),
      );
    } catch (error) {
      state = AsyncValue.data(previous);
      rethrow;
    } finally {
      ref.read(taskMutationLoadingProvider.notifier).state = false;
    }
  }

  Future<void> updateTask({
    required int id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedBy,
    bool setBlockedBy = false,
    int? categoryId,
    bool setCategoryId = false,
  }) async {
    if (ref.read(taskMutationLoadingProvider)) {
      return;
    }

    ref.read(taskMutationLoadingProvider.notifier).state = true;

    final previous = state.valueOrNull ?? <TaskEntity>[];
    final oldTask = previous.where((task) => task.id == id).firstOrNull;

    try {
      final updated = await _withAuthGuard(
        () => _repository.updateTask(
          id: id,
          title: title,
          description: description,
          dueDate: dueDate,
          status: status,
          blockedBy: blockedBy,
          setBlockedBy: setBlockedBy,
          categoryId: categoryId,
          setCategoryId: setCategoryId,
        ),
      );

      state = AsyncValue.data(
        previous
            .map((task) => task.id == id ? updated : task)
            .toList(growable: false),
      );
      await _notifyIfEnabled(
        () => NotificationService.instance.showTaskUpdated(updated.title),
      );
      await NotificationService.instance.cancelTaskReminder(id);
      await _notifyIfEnabled(
        () => NotificationService.instance.scheduleTaskReminder(
          taskId: updated.id,
          title: updated.title,
          dueDate: updated.dueDate,
        ),
      );
    } catch (error) {
      state = AsyncValue.data(previous);
      if (oldTask != null) {
        await _notifyIfEnabled(
          () => NotificationService.instance.scheduleTaskReminder(
            taskId: oldTask.id,
            title: oldTask.title,
            dueDate: oldTask.dueDate,
          ),
        );
      }
      rethrow;
    } finally {
      ref.read(taskMutationLoadingProvider.notifier).state = false;
    }
  }

  Future<void> deleteTask(int id) async {
    final previous = state.valueOrNull ?? <TaskEntity>[];
    final taskToDelete = previous.where((task) => task.id == id).firstOrNull;

    try {
      await _withAuthGuard(() => _repository.deleteTask(id));
      await NotificationService.instance.cancelTaskReminder(id);
      ref.invalidate(allTasksProvider);
      state = AsyncValue.data(
          previous.where((task) => task.id != id).toList(growable: false));
      if (taskToDelete != null) {
        await _notifyIfEnabled(
          () =>
              NotificationService.instance.showTaskDeleted(taskToDelete.title),
        );
      }
    } catch (error) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> addSubtask({
    required int taskId,
    required String title,
  }) async {
    if (title.trim().isEmpty) {
      return;
    }

    final previous = state.valueOrNull ?? <TaskEntity>[];
    try {
      final updatedTask = await _withAuthGuard(
        () => _repository.addSubtask(taskId: taskId, title: title.trim()),
      );
      state = AsyncValue.data(
        previous
            .map((task) => task.id == taskId ? updatedTask : task)
            .toList(growable: false),
      );
    } catch (error) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> toggleSubtask({
    required int taskId,
    required int subtaskId,
    required bool isCompleted,
  }) async {
    final previous = state.valueOrNull ?? <TaskEntity>[];
    try {
      final updatedTask = await _withAuthGuard(
        () => _repository.updateSubtask(
          taskId: taskId,
          subtaskId: subtaskId,
          isCompleted: isCompleted,
        ),
      );
      state = AsyncValue.data(
        previous
            .map((task) => task.id == taskId ? updatedTask : task)
            .toList(growable: false),
      );
    } catch (error) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> deleteSubtask({
    required int taskId,
    required int subtaskId,
  }) async {
    final previous = state.valueOrNull ?? <TaskEntity>[];
    try {
      final updatedTask = await _withAuthGuard(
        () => _repository.deleteSubtask(taskId: taskId, subtaskId: subtaskId),
      );
      state = AsyncValue.data(
        previous
            .map((task) => task.id == taskId ? updatedTask : task)
            .toList(growable: false),
      );
    } catch (error) {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}

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
    this.categoryId,
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
  final int? categoryId;
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
    int? categoryId,
    bool clearCategoryId = false,
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
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
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
      categoryId: task.categoryId,
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

  void setCategoryId(int? value) {
    if (value == null) {
      state = state.copyWith(
        clearCategoryId: true,
        submissionStatus: TaskFormSubmissionStatus.idle,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      categoryId: value,
      submissionStatus: TaskFormSubmissionStatus.idle,
      clearErrorMessage: true,
    );
  }

  Future<bool> submit() async {
    if (state.isLoading || ref.read(taskMutationLoadingProvider)) {
      return false;
    }

    final validationMessage = _validate();
    if (validationMessage != null) {
      state = state.copyWith(
        submissionStatus: TaskFormSubmissionStatus.error,
        errorMessage: validationMessage,
      );
      return false;
    }

    state = state.copyWith(
      submissionStatus: TaskFormSubmissionStatus.loading,
      clearErrorMessage: true,
    );

    try {
      final taskNotifier = ref.read(taskProvider.notifier);

      if (state.isEditMode) {
        await taskNotifier.updateTask(
          id: state.editingTaskId!,
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate!,
          status: state.status,
          blockedBy: state.blockedBy,
          setBlockedBy: true,
          categoryId: state.categoryId,
          setCategoryId: true,
        );
      } else {
        await taskNotifier.createTask(
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate!,
          status: state.status,
          blockedBy: state.blockedBy,
          categoryId: state.categoryId,
        );
      }

      ref.invalidate(taskProvider);
      ref.invalidate(allTasksProvider);

      ref.invalidateSelf();

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
    if (error is ApiException) {
      return error.message;
    }
    if (error is NetworkException) {
      return error.message;
    }
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
}

final taskFormProvider =
    NotifierProvider.family<TaskFormNotifier, TaskFormState, String>(
  TaskFormNotifier.new,
);
