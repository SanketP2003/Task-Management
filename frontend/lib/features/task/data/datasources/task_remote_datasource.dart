import '../../../../core/network/api_client.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TaskModel>> fetchTasks({
    TaskStatus? status,
    String? search,
  }) async {
    final queryParameters = <String, String>{};
    if (status != null) {
      queryParameters['status'] = status.apiValue;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
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
  }) async {
    final response = await _apiClient.post(
      '/tasks',
      body: {
        'title': title,
        'description': description,
        'due_date': dueDate.toUtc().toIso8601String(),
        'status': status.apiValue,
        'blocked_by': blockedBy,
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

    final response = await _apiClient.put('/tasks/$id', body: body);
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteTask(int id) async {
    await _apiClient.delete('/tasks/$id');
  }
}