import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/family_service.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyService _familyService;
  List<UserProfile> _familyMembers = [];
  bool _isLoading = false;
  String? _error;

  FamilyProvider(this._familyService);

  List<UserProfile> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFamilyMembers(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _familyMembers = await _familyService.getFamilyMembers(familyId);
      _error = null;
    } catch (e, s) {
      logger.e('Error loading family members: $e', error: e, stackTrace: s);
      _error = 'Failed to load family members';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFamilyMembers(String familyId) async {
    await loadFamilyMembers(familyId);
  }
}
