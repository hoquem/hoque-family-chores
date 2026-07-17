import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/status_pill.dart';

void main() {
  testWidgets('inProgress renders the play icon and its label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: const Scaffold(
        body: StatusPill(status: TaskStatus.inProgress, label: 'In progress'),
      ),
    ));
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });
}
