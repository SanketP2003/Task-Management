import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';

const _baseUrl = 'http://localhost:8000/api/v1';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _baseUrl);
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

final taskMutationLoadingProvider = StateProvider<bool>((ref) {
  return false;
});

final taskProvider =
    AsyncNotifierProvider<TaskNotifier, List<TaskEntity>>(TaskNotifier.new);

final allTasksProvider =
    AsyncNotifierProvider<AllTasksNotifier, List<TaskEntity>>(
        AllTasksNotifier.new);

class AllTasksNotifier extends AsyncNotifier<List<TaskEntity>> {
  @override
  Future<List<TaskEntity>> build() async {
    return ref.read(taskRepositoryProvider).fetchTasks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(taskRepositoryProvider).fetchTasks());
  }
}

class TaskNotifier extends AsyncNotifier<List<TaskEntity>> {
  late final TaskRepository _repository;

  String get _searchQuery {
    final value = ref.read(taskSearchQueryProvider).trim();
    return value;
  }

  TaskStatus? get _selectedStatus => ref.read(taskStatusFilterProvider);

  @override
  Future<List<TaskEntity>> build() async {
    _repository = ref.read(taskRepositoryProvider);
    return _repository.fetchTasks(
      status: _selectedStatus,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchTasks(
        status: _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
  }) async {
    if (ref.read(taskMutationLoadingProvider)) {
      return;
    }

    ref.read(taskMutationLoadingProvider.notifier).state = true;

    final previous = state.valueOrNull ?? <TaskEntity>[];
    state = const AsyncValue.loading();

    try {
      final created = await _repository.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        blockedBy: blockedBy,
      );

      state = AsyncValue.data([created, ...previous]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
  }) async {
    if (ref.read(taskMutationLoadingProvider)) {
      return;
    }

    ref.read(taskMutationLoadingProvider.notifier).state = true;

    final previous = state.valueOrNull ?? <TaskEntity>[];
    state = const AsyncValue.loading();

    try {
      final updated = await _repository.updateTask(
        id: id,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        blockedBy: blockedBy,
        setBlockedBy: setBlockedBy,
      );

      state = AsyncValue.data(
        previous
            .map((task) => task.id == id ? updated : task)
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      ref.read(taskMutationLoadingProvider.notifier).state = false;
    }
  }

  Future<void> deleteTask(int id) async {
    final previous = state.valueOrNull ?? <TaskEntity>[];
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.deleteTask(id);
      ref.invalidate(allTasksProvider);
      return previous.where((task) => task.id != id).toList(growable: false);
    });
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
        );
      } else {
        await taskNotifier.createTask(
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate!,
          status: state.status,
          blockedBy: state.blockedBy,
        );
      }

      ref.invalidate(taskProvider);
      ref.invalidate(allTasksProvider);

      // Clear draft on successful submission to prevent draft from reappearing when creating a new task next time
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
