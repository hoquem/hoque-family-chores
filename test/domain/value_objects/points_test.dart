import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

void main() {
  group('Points', () {
    test('creates with valid value', () {
      final points = Points(100);
      expect(points.value, 100);
    });

    test('creates zero points', () {
      final points = Points(0);
      expect(points.value, 0);
      expect(points.isZero, true);
    });

    test('throws on negative value', () {
      expect(() => Points(-1), throwsArgumentError);
    });

    test('zero constant', () {
      expect(Points.zero.value, 0);
      expect(Points.zero.isZero, true);
    });

    test('isPositive', () {
      expect(Points(10).isPositive, true);
      expect(Points(0).isPositive, false);
    });

    test('add', () {
      final result = Points(10).add(Points(5));
      expect(result.value, 15);
    });

    test('addInt', () {
      expect(Points(10).addInt(5).value, 15);
    });

    test('subtract', () {
      expect(Points(10).subtract(Points(3)).value, 7);
    });

    test('subtract throws when result would be negative', () {
      expect(() => Points(5).subtract(Points(10)), throwsArgumentError);
    });

    test('subtractInt', () {
      expect(Points(10).subtractInt(3).value, 7);
    });

    test('multiply', () {
      expect(Points(10).multiply(1.5).value, 15);
    });

    test('multiply by zero', () {
      expect(Points(10).multiply(0).value, 0);
    });

    test('multiply throws on negative factor', () {
      expect(() => Points(10).multiply(-1), throwsArgumentError);
    });

    test('comparison methods', () {
      expect(Points(10).isGreaterThan(Points(5)), true);
      expect(Points(5).isLessThan(Points(10)), true);
      expect(Points(10).isEqualTo(Points(10)), true);
      expect(Points(10).isGreaterThan(Points(10)), false);
    });

    test('equality via Equatable', () {
      expect(Points(10), equals(Points(10)));
      expect(Points(10), isNot(equals(Points(20))));
    });

    test('tryCreate returns null for invalid', () {
      expect(Points.tryCreate(-1), isNull);
      expect(Points.tryCreate(10)?.value, 10);
    });

    test('toString returns value string', () {
      expect(Points(42).toString(), '42');
    });

    test('toInt returns value', () {
      expect(Points(42).toInt(), 42);
    });
  });
}
