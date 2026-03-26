import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<TaskEntity>> fetchTasks({TaskStatus? status, String? search}) {
    return _remoteDataSource.fetchTasks(status: status, search: search);
  }

  @override
  Future<TaskEntity> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
  }) {
    return _remoteDataSource.createTask(
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedBy: blockedBy,
    );
  }

  @override
  Future<TaskEntity> updateTask({
    required int id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedBy,
    bool setBlockedBy = false,
  }) {
    return _remoteDataSource.updateTask(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedBy: blockedBy,
      includeBlockedBy: setBlockedBy,
    );
  }

  @override
  Future<void> deleteTask(int id) {
    return _remoteDataSource.deleteTask(id);
  }
}