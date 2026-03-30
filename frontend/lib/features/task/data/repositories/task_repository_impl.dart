import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._remoteDataSource);

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<TaskEntity>> fetchTasks({
    TaskStatus? status,
    String? search,
    int? categoryId,
  }) {
    return _remoteDataSource.fetchTasks(
      status: status,
      search: search,
      categoryId: categoryId,
    );
  }

  @override
  Future<TaskEntity> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
    int? categoryId,
  }) {
    return _remoteDataSource.createTask(
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedBy: blockedBy,
      categoryId: categoryId,
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
    int? categoryId,
    bool setCategoryId = false,
  }) {
    return _remoteDataSource.updateTask(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedBy: blockedBy,
      includeBlockedBy: setBlockedBy,
      categoryId: categoryId,
      includeCategoryId: setCategoryId,
    );
  }

  @override
  Future<void> deleteTask(int id) {
    return _remoteDataSource.deleteTask(id);
  }

  @override
  Future<TaskEntity> addSubtask({
    required int taskId,
    required String title,
  }) {
    return _remoteDataSource.addSubtask(taskId: taskId, title: title);
  }

  @override
  Future<TaskEntity> updateSubtask({
    required int taskId,
    required int subtaskId,
    String? title,
    bool? isCompleted,
  }) {
    return _remoteDataSource.updateSubtask(
      taskId: taskId,
      subtaskId: subtaskId,
      title: title,
      isCompleted: isCompleted,
    );
  }

  @override
  Future<TaskEntity> deleteSubtask({
    required int taskId,
    required int subtaskId,
  }) {
    return _remoteDataSource.deleteSubtask(
        taskId: taskId, subtaskId: subtaskId);
  }

  @override
  Future<List<CategoryEntity>> fetchCategories() {
    return _remoteDataSource.fetchCategories();
  }

  @override
  Future<CategoryEntity> createCategory({required String name}) {
    return _remoteDataSource.createCategory(name: name);
  }

  @override
  Future<CategoryEntity> updateCategory({
    required int categoryId,
    required String name,
  }) {
    return _remoteDataSource.updateCategory(categoryId: categoryId, name: name);
  }

  @override
  Future<void> deleteCategory(int categoryId) {
    return _remoteDataSource.deleteCategory(categoryId);
  }
}
