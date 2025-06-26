import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/services/interfaces/badge_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'auth_provider.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeServiceInterface _badgeService;
  final _logger = AppLogger();
  List<Badge> _badges = [];
  bool _isLoading = false;
  String? _errorMessage;
  final AuthProvider _authProvider;
  VoidCallback? _authListener;

  BadgeProvider(this._badgeService, this._authProvider) {
    _authListener = () {
      final familyId = _authProvider.userFamilyId;
      if (familyId != null) {
        _logger.d('AuthProvider changed, fetching badges for family $familyId');
        fetchBadges(familyId);
      }
    };
    _authProvider.addListener(_authListener!);
    // Initial fetch if familyId is available
    final familyId = _authProvider.userFamilyId;
    if (familyId != null) {
      fetchBadges(familyId);
    }
  }

  @override
  void dispose() {
    if (_authListener != null) {
      _authProvider.removeListener(_authListener!);
    }
    super.dispose();
  }

  List<Badge> get badges => _badges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBadges(String familyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.d('Fetching badges for family $familyId');
      _badges = await _badgeService.getBadges(familyId: familyId);
      _logger.d('Fetched ${_badges.length} badges');

      // If no badges exist, create a default one
      if (_badges.isEmpty) {
        _logger.d('No badges found, creating a default badge...');
        await createBadge(
          familyId: familyId,
          name: 'Welcome Badge',
          description: 'This is your first badge! Edit or delete as needed.',
          iconName: 'emoji_events',
          requiredPoints: 10,
          type: BadgeType.taskCompletion,
          creatorId: null,
        );
        // Fetch again to update the list
        _badges = await _badgeService.getBadges(familyId: familyId);
      }
    } catch (e, s) {
      _logger.e('Error fetching badges: $e', error: e, stackTrace: s);
      _errorMessage = 'Error fetching badges: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBadge({
    required String familyId,
    required String name,
    required String description,
    required String iconName,
    required int requiredPoints,
    required BadgeType type,
    String? creatorId,
  }) async {
    try {
      _logger.d('Creating new badge for family $familyId');
      final badge = Badge(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        iconName: iconName,
        requiredPoints: requiredPoints,
        type: type,
        familyId: familyId,
        creatorId: creatorId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _badgeService.createBadge(familyId: familyId, badge: badge);
      _logger.d('Badge created successfully');

      // Refresh badges list
      await fetchBadges(familyId);
    } catch (e, s) {
      _logger.e('Error creating badge: $e', error: e, stackTrace: s);
      _errorMessage = 'Error creating badge: $e';
      notifyListeners();
    }
  }

  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    String? name,
    String? description,
    String? iconName,
    int? requiredPoints,
    BadgeType? type,
  }) async {
    try {
      _logger.d('Updating badge $badgeId for family $familyId');
      final badge = _badges.firstWhere((b) => b.id == badgeId);

      final updatedBadge = badge.copyWith(
        name: name,
        description: description,
        iconName: iconName,
        requiredPoints: requiredPoints,
        type: type,
        updatedAt: DateTime.now(),
      );

      await _badgeService.updateBadge(
        familyId: familyId,
        badgeId: badgeId,
        badge: updatedBadge,
      );
      _logger.d('Badge updated successfully');

      // Refresh badges list
      await fetchBadges(familyId);
    } catch (e, s) {
      _logger.e('Error updating badge: $e', error: e, stackTrace: s);
      _errorMessage = 'Error updating badge: $e';
      notifyListeners();
    }
  }

  Future<void> deleteBadge({
    required String familyId,
    required String badgeId,
  }) async {
    try {
      _logger.d('Deleting badge $badgeId from family $familyId');
      await _badgeService.deleteBadge(familyId: familyId, badgeId: badgeId);
      _logger.d('Badge deleted successfully');

      // Refresh badges list
      await fetchBadges(familyId);
    } catch (e, s) {
      _logger.e('Error deleting badge: $e', error: e, stackTrace: s);
      _errorMessage = 'Error deleting badge: $e';
      notifyListeners();
    }
  }
}
