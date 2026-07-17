// Task 3 of the before/after-photos feature threads `requiresPhotoProof`
// through four layers: screen -> notifier -> use case -> Task. The switch
// itself is covered by test/presentation/add_task_photo_proof_test.dart, but
// nothing there proves the flag survives the use case's Task construction —
// if a layer silently drops it, every existing test stays green (this is the
// exact rot pattern that shipped an unused photo-proof data layer for months
// before). This test closes that seam: it captures the Task actually handed
// to the repository and asserts the flag rode along.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repository;
  late CreateTaskUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      Task(
        id: TaskId('fallback'),
        title: 'fallback',
        description: '',
        status: TaskStatus.available,
        difficulty: TaskDifficulty.easy,
        dueDate: DateTime(2025, 1, 1),
        createdById: UserId('fallback'),
        createdAt: DateTime(2025, 1, 1),
        points: Points(1),
        tags: const [],
        familyId: FamilyId('fallback'),
      ),
    );
  });

  setUp(() {
    repository = MockTaskRepository();
    useCase = CreateTaskUseCase(repository);

    when(() => repository.createTask(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as Task,
    );
  });

  Future<Task> captureTask() async {
    final captured = verify(() => repository.createTask(captureAny()))
        .captured
        .single as Task;
    return captured;
  }

  test('requiresPhotoProof: true reaches the Task passed to the repository',
      () async {
    await useCase.call(
      title: 'Clean the garage',
      points: 10,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      familyId: FamilyId('fam_1'),
      createdById: UserId('parent_1'),
      requiresPhotoProof: true,
    );

    final task = await captureTask();
    expect(task.requiresPhotoProof, isTrue);
  });

  test('requiresPhotoProof defaults to false when omitted', () async {
    await useCase.call(
      title: 'Clean the garage',
      points: 10,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      familyId: FamilyId('fam_1'),
      createdById: UserId('parent_1'),
    );

    final task = await captureTask();
    expect(task.requiresPhotoProof, isFalse);
  });
}
