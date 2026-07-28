import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/core/utils/task_repeat_mapper.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

void main() {
  group('TaskRepeatMapper Tests', () {
    test('Converts UI strings to DB compliant values', () {
      expect(TaskRepeatMapper.toDb('No Repeat'), equals('none'));
      expect(TaskRepeatMapper.toDb('None'), equals('none'));
      expect(TaskRepeatMapper.toDb('Daily'), equals('daily'));
      expect(TaskRepeatMapper.toDb('Weekly'), equals('weekly'));
      expect(TaskRepeatMapper.toDb('Monthly'), equals('monthly'));
      expect(TaskRepeatMapper.toDb('Yearly'), equals('yearly'));
    });

    test('Converts enum style strings to DB compliant values', () {
      expect(TaskRepeatMapper.toDb('Repeat.daily'), equals('daily'));
      expect(TaskRepeatMapper.toDb('RepeatType.weekly'), equals('weekly'));
    });

    test('Converts unrecognized or null input to none', () {
      expect(TaskRepeatMapper.toDb(null), equals('none'));
      expect(TaskRepeatMapper.toDb(''), equals('none'));
      expect(TaskRepeatMapper.toDb('InvalidValue'), equals('none'));
    });

    test('Converts DB values to UI display text', () {
      expect(TaskRepeatMapper.toUi('none'), equals('No Repeat'));
      expect(TaskRepeatMapper.toUi('daily'), equals('Daily'));
      expect(TaskRepeatMapper.toUi('weekly'), equals('Weekly'));
      expect(TaskRepeatMapper.toUi('monthly'), equals('Monthly'));
      expect(TaskRepeatMapper.toUi('yearly'), equals('Yearly'));
    });

    test('isRepeating correctly identifies recurring tasks', () {
      expect(TaskRepeatMapper.isRepeating('none'), isFalse);
      expect(TaskRepeatMapper.isRepeating('No Repeat'), isFalse);
      expect(TaskRepeatMapper.isRepeating('daily'), isTrue);
      expect(TaskRepeatMapper.isRepeating('weekly'), isTrue);
    });
  });

  group('TaskModel Serialization with TaskRepeatMapper Tests', () {
    test('TaskModel sanitizes repeat value on creation', () {
      final task = TaskModel(
        id: '1',
        businessId: '',
        title: 'Test',
        description: '',
        priority: 'Medium',
        dueDate: DateTime.now(),
        assignedto: 'user1',
        createdAt: DateTime.now(),
        repeat: 'Daily',
      );
      expect(task.repeat, equals('daily'));
      expect(task.repeatDisplay, equals('Daily'));
      expect(task.toMap()['repeat'], equals('daily'));
    });

    test('TaskModel deserializes raw DB map properly', () {
      final map = {
        'id': '2',
        'title': 'Sample Task',
        'repeat': 'weekly',
        'due_date': DateTime.now().toIso8601String(),
      };
      final task = TaskModel.fromMap(map);
      expect(task.repeat, equals('weekly'));
      expect(task.repeatDisplay, equals('Weekly'));
    });

    test('Personal task mapping sets business_id to null and task_type to personal', () {
      final personalTask = TaskModel(
        id: '100',
        businessId: '',
        title: 'Personal Task',
        description: 'No business attached',
        priority: 'High',
        dueDate: DateTime.now(),
        assignedto: 'user-uuid-1',
        createdBy: 'user-uuid-1',
        createdAt: DateTime.now(),
        taskType: 'personal',
      );

      final map = personalTask.toMap();
      expect(map['business_id'], isNull);
      expect(map['task_type'], equals('personal'));
      expect(map['assigned_to'], equals('user-uuid-1'));
      expect(map['created_by'], equals('user-uuid-1'));
    });

    test('TaskModel.toMap converts empty string UUIDs to null', () {
      final emptyUuidTask = TaskModel(
        id: '',
        businessId: '',
        title: 'Unassigned Task',
        description: '',
        priority: 'Low',
        dueDate: DateTime.now(),
        assignedto: '',
        createdBy: '',
        ownerId: '',
        createdAt: DateTime.now(),
      );

      final map = emptyUuidTask.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['business_id'], isNull);
      expect(map['assigned_to'], isNull);
      expect(map['created_by'], isNull);
      expect(map['owner_id'], isNull);
    });
  });
}
