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

final taskProvider = AsyncNotifierProvider<TaskNotifier, List<TaskEntity>>(TaskNotifier.new);

class TaskNotifier extends AsyncNotifier<List<TaskEntity>> {
  late final TaskRepository _repository;

  @override
  Future<List<TaskEntity>> build() async {
    _repository = ref.read(taskRepositoryProvider);
    return _repository.fetchTasks();
  }

  Future<void> refresh({TaskStatus? status, String? search}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchTasks(status: status, search: search),
    );
  }

  Future<void> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
  }) async {
    final previous = state.valueOrNull ?? <TaskEntity>[];
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final created = await _repository.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        blockedBy: blockedBy,
      );
      return [created, ...previous];
    });
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
    final previous = state.valueOrNull ?? <TaskEntity>[];
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final updated = await _repository.updateTask(
        id: id,
        title: title,
        description: description,
        dueDate: dueDate,
        status: status,
        blockedBy: blockedBy,
        setBlockedBy: setBlockedBy,
      );

      return previous
          .map((task) => task.id == id ? updated : task)
          .toList(growable: false);
    });
  }

  Future<void> deleteTask(int id) async {
    final previous = state.valueOrNull ?? <TaskEntity>[];
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.deleteTask(id);
      return previous.where((task) => task.id != id).toList(growable: false);
    });
  }
}
