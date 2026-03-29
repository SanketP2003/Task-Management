import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/core/network/api_client.dart';
import 'package:task_manager_app/features/task/data/datasources/task_remote_datasource.dart';
import 'package:task_manager_app/features/task/data/repositories/task_repository_impl.dart';
import 'package:task_manager_app/features/task/domain/entities/task_entity.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TaskRemoteDataSource remoteDataSource;
  late TaskRepositoryImpl repository;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteDataSource = TaskRemoteDataSource(mockApiClient);
    repository = TaskRepositoryImpl(remoteDataSource);
  });

  final tTaskEntity = TaskEntity(
    id: 1,
    title: 'Test Task',
    description: 'Test Description',
    status: TaskStatus.todo,
    dueDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    blockedBy: null,
  );

  final tTaskJson = {
    'id': 1,
    'title': 'Test Task',
    'description': 'Test Description',
    'status': 'todo',
    'due_date': '2026-01-01T00:00:00.000',
    'created_at': '2026-01-01T00:00:00.000',
    'updated_at': '2026-01-01T00:00:00.000',
    'blocked_by': null,
  };

  group('TaskRepositoryImpl Tests', () {
    test(
        'fetchTasks should return list of TaskEntity when API call is successful',
        () async {
      when(() => mockApiClient.get(
            '/tasks',
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => [tTaskJson]);

      final result = await repository.fetchTasks();

      expect(result.length, 1);
      expect(result.first.id, tTaskEntity.id);
      expect(result.first.title, tTaskEntity.title);
      verify(() => mockApiClient.get('/tasks', queryParameters: {})).called(1);
    });

    test('fetchTasks should throw an exception when API call fails', () async {
      when(() => mockApiClient.get(
            '/tasks',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(ApiException(statusCode: 500, message: 'Server Error'));

      expect(() => repository.fetchTasks(), throwsA(isA<ApiException>()));
    });

    test('createTask should return TaskEntity when successful', () async {
      when(() => mockApiClient.post('/tasks', body: any(named: 'body')))
          .thenAnswer((_) async => tTaskJson);

      final result = await repository.createTask(
        title: 'Test Task',
        description: 'Test Description',
        dueDate: DateTime(2026, 1, 1),
        status: TaskStatus.todo,
      );

      expect(result.id, tTaskEntity.id);
      expect(result.title, tTaskEntity.title);
      verify(() => mockApiClient.post('/tasks', body: any(named: 'body')))
          .called(1);
    });

    test('updateTask should return TaskEntity when successful', () async {
      when(() => mockApiClient.put('/tasks/1', body: any(named: 'body')))
          .thenAnswer((_) async => tTaskJson);

      final result = await repository.updateTask(
        id: 1,
        title: 'Updated Task',
      );

      expect(result.id, tTaskEntity.id);
      verify(() => mockApiClient.put('/tasks/1', body: any(named: 'body')))
          .called(1);
    });

    test('deleteTask should complete without error when successful', () async {
      when(() => mockApiClient.delete('/tasks/1'))
          .thenAnswer((_) async => null);

      expect(() => repository.deleteTask(1), returnsNormally);
      verify(() => mockApiClient.delete('/tasks/1')).called(1);
    });
  });
}
