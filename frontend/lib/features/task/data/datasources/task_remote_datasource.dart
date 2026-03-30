import '../../../../core/network/api_client.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TaskModel>> fetchTasks({
    TaskStatus? status,
    String? search,
    int? categoryId,
  }) async {
    final queryParameters = <String, String>{};
    if (status != null) {
      queryParameters['status'] = status.apiValue;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }
    if (categoryId != null) {
      queryParameters['category_id'] = categoryId.toString();
    }

    final response = await _apiClient.get(
      '/tasks',
      queryParameters: queryParameters,
    );

    final list = response as List<dynamic>? ?? <dynamic>[];
    return list
        .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    TaskStatus status = TaskStatus.todo,
    int? blockedBy,
    int? categoryId,
  }) async {
    final response = await _apiClient.post(
      '/tasks',
      body: {
        'title': title,
        'description': description,
        'due_date': dueDate.toUtc().toIso8601String(),
        'status': status.apiValue,
        'blocked_by': blockedBy,
        'category_id': categoryId,
      },
    );

    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<TaskModel> updateTask({
    required int id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedBy,
    bool includeBlockedBy = false,
    int? categoryId,
    bool includeCategoryId = false,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) {
      body['title'] = title;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (dueDate != null) {
      body['due_date'] = dueDate.toUtc().toIso8601String();
    }
    if (status != null) {
      body['status'] = status.apiValue;
    }
    if (includeBlockedBy) {
      body['blocked_by'] = blockedBy;
    }
    if (includeCategoryId) {
      body['category_id'] = categoryId;
    }

    final response = await _apiClient.put('/tasks/$id', body: body);
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteTask(int id) async {
    await _apiClient.delete('/tasks/$id');
  }

  Future<TaskModel> addSubtask({
    required int taskId,
    required String title,
  }) async {
    final response = await _apiClient.post(
      '/tasks/$taskId/subtasks',
      body: {'title': title},
    );
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<TaskModel> updateSubtask({
    required int taskId,
    required int subtaskId,
    String? title,
    bool? isCompleted,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) {
      body['title'] = title;
    }
    if (isCompleted != null) {
      body['is_completed'] = isCompleted;
    }

    final response = await _apiClient.put(
      '/tasks/$taskId/subtasks/$subtaskId',
      body: body,
    );
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<TaskModel> deleteSubtask({
    required int taskId,
    required int subtaskId,
  }) async {
    final response =
        await _apiClient.delete('/tasks/$taskId/subtasks/$subtaskId');
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _apiClient.get('/categories');
    final list = response as List<dynamic>? ?? <dynamic>[];
    return list
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CategoryModel> createCategory({required String name}) async {
    final response = await _apiClient.post('/categories', body: {'name': name});
    return CategoryModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    final response =
        await _apiClient.put('/categories/$categoryId', body: {'name': name});
    return CategoryModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int categoryId) async {
    await _apiClient.delete('/categories/$categoryId');
  }
}
