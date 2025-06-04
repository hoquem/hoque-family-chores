import 'package:flutter/foundation.dart'; // For ChangeNotifier
import '../../models/family_member.dart';
import '../../services/family_service_interface.dart';

enum FamilyListState { initial, loading, loaded, error }

class FamilyListProvider with ChangeNotifier {
  final FamilyServiceInterface _familyService;

  FamilyListProvider(this._familyService) {
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

  Future<void> fetchFamilyMembers() async {
    _state = FamilyListState.loading;
    notifyListeners();

    try {
      _members = await _familyService.getFamilyMembers();
      _state = FamilyListState.loaded;
    } catch (error) {
      _state = FamilyListState.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  } 
}