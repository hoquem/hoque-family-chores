import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyServiceInterface _familyService;
  final _logger = AppLogger();
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = false;
  String? _error;

  FamilyProvider(this._familyService);

  List<FamilyMember> get familyMembers => _familyMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFamilyMembers(String familyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _familyMembers = await _familyService.getFamilyMembers(
        familyId: familyId,
      );
      _error = null;
    } catch (e, s) {
      _logger.e('Error loading family members: $e', error: e, stackTrace: s);
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
