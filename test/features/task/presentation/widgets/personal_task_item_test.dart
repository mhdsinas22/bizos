import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/task/presentation/widgets/personal_task_item.dart';
import 'package:bizos/core/theme/app_theme.dart';

void main() {
  Widget buildTestWidget({
    required TaskModel task,
    required double width,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: PersonalTaskItem(
              task: task,
              onToggleComplete: (_) {},
              onEdit: () {},
              onDelete: () {},
              onLongPress: () {},
              onResolveCompletedLate: () {},
              onResolveNotCompleted: () {},
            ),
          ),
        ),
      ),
    );
  }

  group('PersonalTaskItem Overflow and UI/UX Tests', () {
    testWidgets(
        'renders Not Completed task without RenderFlex overflow on 390px (iPhone width)',
        (tester) async {
      final task = TaskModel(
        id: '1',
        businessId: '',
        title: 'Wake Up at 4:30',
        description: '',
        priority: 'High',
        dueDate: DateTime(2026, 10, 24, 4, 25),
        assignedto: 'user_1',
        createdAt: DateTime.now(),
        status: 'Not Completed',
        repeat: 'daily',
      );

      await tester.pumpWidget(
        buildTestWidget(task: task, width: 358), // 390 screen - 32 list padding
      );

      // Verify no exceptions / RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Wake Up at 4:30'), findsOneWidget);
      expect(find.textContaining('Not Completed', findRichText: true), findsOneWidget);
      expect(find.textContaining('Daily', findRichText: true), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets(
        'renders Not Completed task without RenderFlex overflow on narrow 320px screen',
        (tester) async {
      final task = TaskModel(
        id: '2',
        businessId: '',
        title: 'Wake Up at 4:30',
        description: '',
        priority: 'High',
        dueDate: DateTime(2026, 10, 24, 4, 25),
        assignedto: 'user_1',
        createdAt: DateTime.now(),
        status: 'Not Completed',
        repeat: 'daily',
      );

      await tester.pumpWidget(
        buildTestWidget(task: task, width: 288), // 320 screen - 32 list padding
      );

      // Verify no exceptions / RenderFlex overflow on small screen
      expect(tester.takeException(), isNull);
      expect(find.text('Wake Up at 4:30'), findsOneWidget);
      expect(find.textContaining('Not Completed', findRichText: true), findsOneWidget);
    });

    testWidgets('renders Completed Late and Overdue tasks without overflow',
        (tester) async {
      final lateTask = TaskModel(
        id: '3',
        businessId: '',
        title: 'Pray Magrib with Jama',
        description: '',
        priority: 'High',
        dueDate: DateTime(2026, 10, 24, 18, 15),
        assignedto: 'user_1',
        createdAt: DateTime.now(),
        status: 'Completed Late',
        repeat: 'daily',
      );

      await tester.pumpWidget(
        buildTestWidget(task: lateTask, width: 358),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Completed Late', findRichText: true), findsOneWidget);
      expect(find.textContaining('Daily', findRichText: true), findsOneWidget);
    });
  });
}
