enum TaskStatus {
  todo,
  inProgress,
  done,
}

class SubtaskEntity {
  const SubtaskEntity({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.taskId,
  });

  final int id;
  final String title;
  final bool isCompleted;
  final int taskId;
}

class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

extension TaskStatusX on TaskStatus {
  String get apiValue {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromApi(String value) {
    switch (value) {
      case 'To-Do':
        return TaskStatus.todo;
      case 'In Progress':
        return TaskStatus.inProgress;
      case 'Done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }
}

class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.blockedBy,
    this.categoryId,
    this.category,
    this.subtasks = const <SubtaskEntity>[],
  });

  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? blockedBy;
  final int? categoryId;
  final CategoryEntity? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SubtaskEntity> subtasks;
}
