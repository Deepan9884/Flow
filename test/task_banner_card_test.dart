import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_todo/features/tasks/models/task.dart';
import 'package:flow_todo/widgets/task_banner_card.dart';

Task _task() => Task(
      uuid: 'u1',
      title: 'Buy milk',
      dueDate: DateTime(2026, 1, 2),
      priority: 1,
      isCompleted: false,
      categoryIds: const ['work'],
      subtasks: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _frame(Widget child) =>
    MaterialApp(home: Scaffold(body: SizedBox(width: 400, child: child)));

void main() {
  group('TaskBannerCard', () {
    testWidgets('renders title and resolved category label', (tester) async {
      await tester.pumpWidget(_frame(TaskBannerCard(
        task: _task(),
        onTap: () {},
        categoryLabel: 'Work',
      )));

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('WORK'), findsOneWidget);
    });

    testWidgets('tap fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_frame(TaskBannerCard(
        task: _task(),
        onTap: () => tapped = true,
      )));

      await tester.tap(find.byType(TaskBannerCard));
      expect(tapped, isTrue);
    });

    testWidgets('toggle and delete actions appear when provided',
        (tester) async {
      var toggled = false;
      var deleted = false;
      await tester.pumpWidget(_frame(TaskBannerCard(
        task: _task(),
        onTap: () {},
        onToggle: () => toggled = true,
        onDelete: () => deleted = true,
      )));

      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(toggled, isTrue);
      expect(deleted, isTrue);
    });
  });
}
