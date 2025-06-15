import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

enum FamilyListState { initial, loading, loaded, error }

class FamilyListProvider with ChangeNotifier {
  final FamilyServiceInterface _familyService;
  final _logger = AppLogger();

  FamilyListProvider(this._familyService) {
    _logger.d('FamilyListProvider initialized');
    // Optionally load family members when the provider is created
    // fetchFamilyMembers();
  }

  FamilyListState _state = FamilyListState.initial;
  List<FamilyMember> _members = [];
  String _errorMessage = '';

  // Getters for the UI to consume
  FamilyListState get state => _state;
  List<FamilyMember> get members => _members;
  String get errorMessage => _errorMessage;

  @override
  void dispose() {
    _logger.d('FamilyListProvider disposed');
    super.dispose();
  }

  Future<void> fetchFamilyMembers({required String familyId}) async {
    _state = FamilyListState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _members = await _familyService.getFamilyMembers(familyId: familyId);
      _state = FamilyListState.loaded;
    } catch (e, s) {
      _logger.e('Error fetching family members: $e', error: e, stackTrace: s);
      _state = FamilyListState.error;
      _errorMessage = 'Failed to fetch family members';
    }

    notifyListeners();
  }
}
