import 'package:equatable/equatable.dart';

/// Value object representing points in the gamification system
class Points extends Equatable {
  final int value;

  const Points._(this.value);

  /// Factory constructor that validates points are non-negative
  factory Points(int points) {
    if (points < 0) {
      throw ArgumentError('Points cannot be negative: $points');
    }
    return Points._(points);
  }

  /// Creates points from an integer, returns null if invalid
  static Points? tryCreate(int points) {
    try {
      return Points(points);
    } catch (e) {
      return null;
    }
  }

  /// Zero points constant
  static const Points zero = Points._(0);

  /// Add points to current value
  Points add(Points other) {
    return Points(value + other.value);
  }

  /// Add integer points to current value
  Points addInt(int other) {
    return add(Points(other));
  }

  /// Subtract points from current value
  Points subtract(Points other) {
    final result = value - other.value;
    if (result < 0) {
      throw ArgumentError('Cannot subtract more points than available');
    }
    return Points(result);
  }

  /// Subtract integer points from current value
  Points subtractInt(int other) {
    return subtract(Points(other));
  }

  /// Multiply points by a factor
  Points multiply(double factor) {
    if (factor < 0) {
      throw ArgumentError('Cannot multiply points by negative factor');
    }
    return Points((value * factor).round());
  }

  /// Check if points are greater than other points
  bool isGreaterThan(Points other) {
    return value > other.value;
  }

  /// Check if points are less than other points
  bool isLessThan(Points other) {
    return value < other.value;
  }

  /// Check if points are equal to other points
  bool isEqualTo(Points other) {
    return value == other.value;
  }

  /// Check if points are zero
  bool get isZero => value == 0;

  /// Check if points are positive
  bool get isPositive => value > 0;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value.toString();

  /// Convert to integer
  int toInt() => value;
} 