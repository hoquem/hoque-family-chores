import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/usecases/gamification/get_badges_usecase.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'badge_notifier.g.dart';

/// Manages badge-related state and operations.
/// 
/// This notifier handles loading badges for a family and provides
/// methods for badge-related operations.
/// 
/// Example:
/// ```dart
/// final badgesAsync = ref.watch(badgeNotifierProvider(familyId));
/// final notifier = ref.read(badgeNotifierProvider(familyId).notifier);
/// await notifier.refresh();
/// ```
@riverpod
class BadgeNotifier extends _$BadgeNotifier {
  final _logger = AppLogger();

  @override
  Future<List<Badge>> build(FamilyId familyId) async {
    _logger.d('BadgeNotifier: Building for family $familyId');
    
    try {
      final getBadgesUseCase = ref.watch(getBadgesUseCaseProvider);
      final result = await getBadgesUseCase.call(familyId: familyId);
      
      return result.fold(
        (failure) => throw Exception(failure.message),
        (badges) {
          _logger.d('BadgeNotifier: Loaded ${badges.length} badges');
          return badges;
        },
      );
    } catch (e) {
      _logger.e('BadgeNotifier: Error loading badges', error: e);
      throw Exception('Failed to load badges: $e');
    }
  }

  /// Refreshes the badges list.
  Future<void> refresh() async {
    _logger.d('BadgeNotifier: Refreshing badges');
    ref.invalidateSelf();
  }

  /// Gets the current list of badges.
  List<Badge> get badges => state.value ?? [];

  /// Gets the current loading state.
  bool get isLoading => state.isLoading;

  /// Gets the current error message.
  String? get errorMessage => state.hasError ? state.error.toString() : null;

  /// Gets badges by rarity.
  List<Badge> getBadgesByRarity(BadgeRarity rarity) {
    return badges.where((badge) => badge.rarity == rarity).toList();
  }

  /// Gets common badges.
  List<Badge> get commonBadges => getBadgesByRarity(BadgeRarity.common);

  /// Gets rare badges.
  List<Badge> get rareBadges => getBadgesByRarity(BadgeRarity.rare);

  /// Gets epic badges.
  List<Badge> get epicBadges => getBadgesByRarity(BadgeRarity.epic);

  /// Gets legendary badges.
  List<Badge> get legendaryBadges => getBadgesByRarity(BadgeRarity.legendary);
} 