import '../entities/task_entity.dart';

abstract class TaskRepository {
	Future<List<TaskEntity>> fetchTasks({
		TaskStatus? status,
		String? search,
	});

	Future<TaskEntity> createTask({
		required String title,
		required String description,
		required DateTime dueDate,
		TaskStatus status = TaskStatus.todo,
		int? blockedBy,
	});

	Future<TaskEntity> updateTask({
		required int id,
		String? title,
		String? description,
		DateTime? dueDate,
		TaskStatus? status,
		int? blockedBy,
		bool setBlockedBy = false,
	});

	Future<void> deleteTask(int id);
}
