import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:bizos/features/task/domain/usecases/process_recurring_task_usecase.dart';

class FakeTaskRepository implements TaskRepository {
  final List<TaskModel> createdTasks = [];
  bool shouldReturnDuplicate = false;

  @override
  Future<void> createTask(TaskModel task) async {
    createdTasks.add(task);
  }

  @override
  Future<bool> checkOccurrenceExists({
    required String title,
    required String repeat,
    required String userId,
    required DateTime dueDate,
  }) async {
    return shouldReturnDuplicate;
  }

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<List<TaskModel>> getAllTasks({required String userId, required bool isOwner}) async => [];

  @override
  Future<Map<String, String>> getBusinessNames(List<String> businessIds) async => {};

  @override
  Future<List<TaskModel>> getPersonalTasks(String userId) async => [];

  @override
  Future<TaskModel> getTaskById(String id) async => createdTasks.first;

  @override
  Future<List<TaskModel>> getTasks(String businessId, String userId, bool isOwner) async => [];

  @override
  Future<Map<String, String>> getUserNames(List<String> userIds) async => {};

  @override
  Future<void> updateTask(TaskModel task) async {}
}

void main() {
  late FakeTaskRepository fakeRepo;
  late ProcessRecurringTaskUseCase usecase;

  setUp(() {
    fakeRepo = FakeTaskRepository();
    usecase = ProcessRecurringTaskUseCase(fakeRepo);
  });

  group('ProcessRecurringTaskUseCase Date Calculations', () {
    test('Daily repeat adds 1 day at exact same time', () {
      final now = DateTime(2026, 7, 28, 4, 30);
      final next = ProcessRecurringTaskUseCase.calculateNextDueDate(now, 'daily');
      expect(next, equals(DateTime(2026, 7, 29, 4, 30)));
    });

    test('Weekly repeat adds 7 days at exact same time', () {
      final now = DateTime(2026, 7, 28, 14, 00);
      final next = ProcessRecurringTaskUseCase.calculateNextDueDate(now, 'weekly');
      expect(next, equals(DateTime(2026, 8, 4, 14, 00)));
    });

    test('Monthly repeat adds 1 month at exact same time', () {
      final now = DateTime(2026, 7, 15, 9, 15);
      final next = ProcessRecurringTaskUseCase.calculateNextDueDate(now, 'monthly');
      expect(next, equals(DateTime(2026, 8, 15, 9, 15)));
    });

    test('Monthly repeat handles day overflow e.g. Jan 31 -> Feb 28', () {
      final jan31 = DateTime(2026, 1, 31, 10, 0);
      final next = ProcessRecurringTaskUseCase.calculateNextDueDate(jan31, 'monthly');
      expect(next, equals(DateTime(2026, 2, 28, 10, 0)));
    });

    test('Yearly repeat adds 1 year at exact same time', () {
      final now = DateTime(2026, 7, 28, 11, 45);
      final next = ProcessRecurringTaskUseCase.calculateNextDueDate(now, 'yearly');
      expect(next, equals(DateTime(2027, 7, 28, 11, 45)));
    });

    test('Yearly repeat handles Feb 29 leap year overflow', () {
      final leapFeb29 = DateTime(2024, 2, 29, 8, 0);
      final next = ProcessRecurringTaskUseCase.calculateNextDueDate(leapFeb29, 'yearly');
      expect(next, equals(DateTime(2025, 2, 28, 8, 0)));
    });
  });

  group('ProcessRecurringTaskUseCase Execution Rules', () {
    test('Does NOT create next task if status is Pending', () async {
      final task = TaskModel(
        id: 't1',
        businessId: '',
        title: 'Wake up early',
        description: '',
        priority: 'High',
        dueDate: DateTime.now(),
        assignedto: 'u1',
        createdAt: DateTime.now(),
        status: 'Pending',
        repeat: 'daily',
      );

      final result = await usecase.execute(task);
      expect(result, isNull);
      expect(fakeRepo.createdTasks, isEmpty);
    });

    test('Does NOT create next task if status is Missed', () async {
      final task = TaskModel(
        id: 't2',
        businessId: '',
        title: 'Morning Yoga',
        description: '',
        priority: 'Medium',
        dueDate: DateTime.now().subtract(const Duration(hours: 2)),
        assignedto: 'u1',
        createdAt: DateTime.now(),
        status: 'Missed',
        repeat: 'daily',
      );

      final result = await usecase.execute(task);
      expect(result, isNull);
      expect(fakeRepo.createdTasks, isEmpty);
    });

    test('Does NOT create next task if repeat is No Repeat', () async {
      final task = TaskModel(
        id: 't3',
        businessId: '',
        title: 'One-off task',
        description: '',
        priority: 'Low',
        dueDate: DateTime.now(),
        assignedto: 'u1',
        createdAt: DateTime.now(),
        status: 'Completed',
        repeat: 'none',
      );

      final result = await usecase.execute(task);
      expect(result, isNull);
      expect(fakeRepo.createdTasks, isEmpty);
    });

    test('Creates next occurrence when Completed', () async {
      final baseDate = DateTime(2026, 7, 28, 7, 0);
      final task = TaskModel(
        id: 't4',
        businessId: '',
        title: 'Daily Standup',
        description: 'Morning alignment',
        priority: 'High',
        dueDate: baseDate,
        assignedto: 'u1',
        createdBy: 'u1',
        createdAt: baseDate,
        status: 'Completed',
        repeat: 'daily',
      );

      final result = await usecase.execute(task);
      expect(result, isNotNull);
      expect(result!.title, equals('Daily Standup'));
      expect(result.dueDate, equals(DateTime(2026, 7, 29, 7, 0)));
      expect(result.status, equals('Pending'));
      expect(result.repeat, equals('daily'));
      expect(fakeRepo.createdTasks.length, equals(1));
    });

    test('Creates next occurrence when Completed Late', () async {
      final baseDate = DateTime(2026, 7, 28, 7, 0);
      final task = TaskModel(
        id: 't5',
        businessId: '',
        title: 'Weekly Report',
        description: '',
        priority: 'Medium',
        dueDate: baseDate,
        assignedto: 'u1',
        createdBy: 'u1',
        createdAt: baseDate,
        status: 'Completed Late',
        repeat: 'weekly',
      );

      final result = await usecase.execute(task);
      expect(result, isNotNull);
      expect(result!.dueDate, equals(DateTime(2026, 8, 4, 7, 0)));
      expect(result.status, equals('Pending'));
      expect(fakeRepo.createdTasks.length, equals(1));
    });

    test('Creates next occurrence when Not Completed', () async {
      final baseDate = DateTime(2026, 7, 28, 7, 0);
      final task = TaskModel(
        id: 't6',
        businessId: '',
        title: 'Monthly Audit',
        description: '',
        priority: 'High',
        dueDate: baseDate,
        assignedto: 'u1',
        createdBy: 'u1',
        createdAt: baseDate,
        status: 'Not Completed',
        repeat: 'monthly',
      );

      final result = await usecase.execute(task);
      expect(result, isNotNull);
      expect(result!.dueDate, equals(DateTime(2026, 8, 28, 7, 0)));
      expect(result.status, equals('Pending'));
      expect(fakeRepo.createdTasks.length, equals(1));
    });

    test('Duplicate prevention stops creation if future occurrence already exists', () async {
      fakeRepo.shouldReturnDuplicate = true;
      final task = TaskModel(
        id: 't7',
        businessId: '',
        title: 'Gym Workout',
        description: '',
        priority: 'Medium',
        dueDate: DateTime(2026, 7, 28, 18, 0),
        assignedto: 'u1',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        status: 'Completed',
        repeat: 'daily',
      );

      final result = await usecase.execute(task);
      expect(result, isNull);
      expect(fakeRepo.createdTasks, isEmpty);
    });
  });
}
