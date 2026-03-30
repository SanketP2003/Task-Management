import '../../domain/entities/task_entity.dart';

class SubtaskModel extends SubtaskEntity {
  const SubtaskModel({
    required super.id,
    required super.title,
    required super.isCompleted,
    required super.taskId,
  });

  factory SubtaskModel.fromJson(Map<String, dynamic> json) {
    return SubtaskModel(
      id: json['id'] as int,
      title: json['title'] as String,
      isCompleted: json['is_completed'] as bool,
      taskId: json['task_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
      'task_id': taskId,
    };
  }
}

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.dueDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.blockedBy,
    super.categoryId,
    super.category,
    super.subtasks,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: TaskStatusX.fromApi(json['status'] as String),
      blockedBy: json['blocked_by'] as int?,
      categoryId: json['category_id'] as int?,
      category: json['category'] == null
          ? null
          : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
      subtasks: (json['subtasks'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => SubtaskModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate,
      status: entity.status,
      blockedBy: entity.blockedBy,
      categoryId: entity.categoryId,
      category: entity.category,
      subtasks: entity.subtasks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status.apiValue,
      'blocked_by': blockedBy,
      'category_id': categoryId,
      'category': category == null
          ? null
          : CategoryModel(id: category!.id, name: category!.name).toJson(),
      'subtasks': subtasks
          .map(
            (subtask) => SubtaskModel(
              id: subtask.id,
              title: subtask.title,
              isCompleted: subtask.isCompleted,
              taskId: subtask.taskId,
            ).toJson(),
          )
          .toList(growable: false),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status.apiValue,
      'blocked_by': blockedBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status.apiValue,
      'blocked_by': blockedBy,
    };
  }
}
