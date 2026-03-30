import '../entities/task_entity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> fetchTasks({
    TaskStatus? status,
    String? search,
    int? categoryId,
  });

  Future<TaskEntity> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
    int? categoryId,
  });

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
  });

  Future<void> deleteTask(int id);

  Future<TaskEntity> addSubtask({
    required int taskId,
    required String title,
  });

  Future<TaskEntity> updateSubtask({
    required int taskId,
    required int subtaskId,
    String? title,
    bool? isCompleted,
  });

  Future<TaskEntity> deleteSubtask({
    required int taskId,
    required int subtaskId,
  });

  Future<List<CategoryEntity>> fetchCategories();

  Future<CategoryEntity> createCategory({required String name});

  Future<CategoryEntity> updateCategory({
    required int categoryId,
    required String name,
  });

  Future<void> deleteCategory(int categoryId);
}
