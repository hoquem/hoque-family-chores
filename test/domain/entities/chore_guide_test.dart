import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/chore_guide.dart';

void main() {
  group('ChoreGuide', () {
    const guide = ChoreGuide(
      motivation: 'Put on your favorite track and beat the timer!',
      steps: ['Step 1', 'Step 2', 'Step 3'],
      forYou: 'Keeps your mind calm.',
      forFamily: 'Lifts a big load off everyone.',
      forHome: 'Keeps our space cozy.',
      takeaway: 'Organization & Focus.',
    );

    test('serializes to and from Map correctly', () {
      final map = guide.toMap();
      final fromMap = ChoreGuide.fromMap(map);

      expect(fromMap, equals(guide));
      expect(fromMap.motivation, guide.motivation);
      expect(fromMap.steps, equals(guide.steps));
      expect(fromMap.forYou, guide.forYou);
      expect(fromMap.forFamily, guide.forFamily);
      expect(fromMap.forHome, guide.forHome);
      expect(fromMap.takeaway, guide.takeaway);
    });

    test('handles empty or missing fields gracefully', () {
      final emptyGuide = ChoreGuide.fromMap({});
      expect(emptyGuide.isEmpty, isTrue);
      expect(emptyGuide.isNotEmpty, isFalse);
      expect(emptyGuide.steps, isEmpty);
      expect(emptyGuide.motivation, '');
    });

    test('equality works with props', () {
      const guide2 = ChoreGuide(
        motivation: 'Put on your favorite track and beat the timer!',
        steps: ['Step 1', 'Step 2', 'Step 3'],
        forYou: 'Keeps your mind calm.',
        forFamily: 'Lifts a big load off everyone.',
        forHome: 'Keeps our space cozy.',
        takeaway: 'Organization & Focus.',
      );
      expect(guide, equals(guide2));
    });

    test('serializes and retains parentTip correctly', () {
      final guideWithTip = guide.copyWith(parentTip: 'Blue bin behind garage');
      final map = guideWithTip.toMap();
      expect(map['parentTip'], 'Blue bin behind garage');

      final deserialized = ChoreGuide.fromMap(map);
      expect(deserialized.parentTip, 'Blue bin behind garage');
      expect(deserialized, equals(guideWithTip));
    });
  });
}
