import 'package:equatable/equatable.dart';

/// Domain entity representing a chore guide/tips
///
/// Contains kid-friendly tips, clean read-only step-by-step instructions,
/// playful motivation, the 'why' (good for you, family, and home),
/// and a life-skill learning takeaway.
class ChoreGuide extends Equatable {
  /// Playful, encouraging pep talk or challenge to inspire action
  final String motivation;

  /// Clear, sequential, practical steps to complete the task
  final List<String> steps;

  /// Why completing this task is good for the child (self-reliance, peace of mind)
  final String forYou;

  /// Why completing this task helps the family (teamwork, care, lightening load)
  final String forFamily;

  /// Why completing this task is good for the home (clean, comfortable sanctuary)
  final String forHome;

  /// Life skill or learning superpower nurtured by this chore
  final String takeaway;

  /// Optional home-specific tip or house note provided by a parent
  final String? parentTip;

  const ChoreGuide({
    required this.motivation,
    required this.steps,
    required this.forYou,
    required this.forFamily,
    required this.forHome,
    required this.takeaway,
    this.parentTip,
  });

  /// Factory constructor to parse from a Firestore map or JSON
  factory ChoreGuide.fromMap(Map<String, dynamic> map) {
    return ChoreGuide(
      motivation: (map['motivation'] as String?)?.trim() ?? '',
      steps: (map['steps'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      forYou: (map['forYou'] as String?)?.trim() ?? '',
      forFamily: (map['forFamily'] as String?)?.trim() ?? '',
      forHome: (map['forHome'] as String?)?.trim() ?? '',
      takeaway: (map['takeaway'] as String?)?.trim() ?? '',
      parentTip: (map['parentTip'] as String?)?.trim(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'motivation': motivation,
      'steps': steps,
      'forYou': forYou,
      'forFamily': forFamily,
      'forHome': forHome,
      'takeaway': takeaway,
      if (parentTip != null && parentTip!.isNotEmpty) 'parentTip': parentTip,
    };
  }

  /// Whether this guide has any populated fields
  bool get isEmpty =>
      motivation.isEmpty &&
      steps.isEmpty &&
      forYou.isEmpty &&
      forFamily.isEmpty &&
      forHome.isEmpty &&
      takeaway.isEmpty &&
      (parentTip == null || parentTip!.isEmpty);

  bool get isNotEmpty => !isEmpty;

  ChoreGuide copyWith({
    String? motivation,
    List<String>? steps,
    String? forYou,
    String? forFamily,
    String? forHome,
    String? takeaway,
    String? parentTip,
  }) {
    return ChoreGuide(
      motivation: motivation ?? this.motivation,
      steps: steps ?? this.steps,
      forYou: forYou ?? this.forYou,
      forFamily: forFamily ?? this.forFamily,
      forHome: forHome ?? this.forHome,
      takeaway: takeaway ?? this.takeaway,
      parentTip: parentTip ?? this.parentTip,
    );
  }

  @override
  List<Object?> get props =>
      [motivation, steps, forYou, forFamily, forHome, takeaway, parentTip];
}
