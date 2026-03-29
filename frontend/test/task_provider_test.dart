import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_manager_app/features/task/domain/entities/task_entity.dart';
import 'package:task_manager_app/features/task/domain/repositories/task_repository.dart';
import 'package:task_manager_app/features/task/presentation/providers/task_provider.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late MockTaskRepository mockRepository;
  late ProviderContainer container;
  late Listener<AsyncValue<List<TaskEntity>>> listener;

  setUpAll(() {
    registerFallbackValue(const AsyncLoading<List<TaskEntity>>());
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    listener = Listener<AsyncValue<List<TaskEntity>>>();
  });

  tearDown(() {
    container.dispose();
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

  group('TaskProvider Tests', () {
    test('initial state is loading and then transitions to data', () async {
      when(() => mockRepository.fetchTasks(status: null, search: null))
          .thenAnswer((_) async => [tTaskEntity]);

      container.listen(
        taskProvider,
        listener.call,
        fireImmediately: true,
      );

      // Verify initial loading state
      verify(() => listener(null, const AsyncLoading<List<TaskEntity>>()))
          .called(1);

      // Wait for the provider to finish building
      await container.read(taskProvider.future);

      // Verify the loaded data
      verify(() => listener(
            any(),
            any(that: isA<AsyncData<List<TaskEntity>>>()),
          )).called(1);
    });

    test('transitions to error state when fetch fails', () async {
      final exception = Exception('Failed to load tasks');
      when(() => mockRepository.fetchTasks(status: null, search: null))
          .thenThrow(exception);

      container.listen(
        taskProvider,
        listener.call,
        fireImmediately: true,
      );

      verify(() => listener(null, const AsyncLoading<List<TaskEntity>>()))
          .called(1);

      try {
        await container.read(taskProvider.future);
      } catch (_) {}

      verify(() => listener(
            any(),
            any(that: isA<AsyncError<List<TaskEntity>>>()),
          )).called(1);
    });

    test('createTask adds a new task to the list', () async {
      // Setup initial data
      when(() => mockRepository.fetchTasks(status: null, search: null))
          .thenAnswer((_) async => []);

      final newTask = TaskEntity(
        id: 2,
        title: 'New Task',
        description: 'Desc',
        status: TaskStatus.todo,
        dueDate: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 2),
        updatedAt: DateTime(2026, 1, 2),
      );

      when(() => mockRepository.createTask(
            title: 'New Task',
            description: 'Desc',
            status: TaskStatus.todo,
            dueDate: any(named: 'dueDate'),
            blockedBy: any(named: 'blockedBy'),
          )).thenAnswer((_) async => newTask);

      await container.read(taskProvider.future); // wait for init

      // Call create
      await container.read(taskProvider.notifier).createTask(
            title: 'New Task',
            description: 'Desc',
            dueDate: DateTime(2026, 1, 2),
          );

      // Verify new task is in state
      final currentState = container.read(taskProvider);
      expect(currentState.value!.length, 1);
      expect(currentState.value!.first.title, 'New Task');
    });

    test('deleteTask removes the task from the list', () async {
      // Setup initial data
      when(() => mockRepository.fetchTasks(status: null, search: null))
          .thenAnswer((_) async => [tTaskEntity]);
      when(() => mockRepository.deleteTask(1)).thenAnswer((_) async => null);

      await container.read(taskProvider.future); // wait for init

      // Verify initial state
      expect(container.read(taskProvider).value!.length, 1);

      // Call delete
      await container.read(taskProvider.notifier).deleteTask(1);

      // Verify task is removed
      expect(container.read(taskProvider).value!.isEmpty, true);
    });
  });
}
