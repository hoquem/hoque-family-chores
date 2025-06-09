// lib/presentation/providers/gamification_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/gamification_service_interface.dart';

enum GamificationState { idle, loading, success, error }

class GamificationProvider with ChangeNotifier {
  GamificationServiceInterface? _gamificationService;
  DataServiceInterface? _dataService;

  UserProfile? _userProfile;
  List<Badge> _allBadges = [];
  List<Reward> _allRewards = [];
  GamificationState _state = GamificationState.idle;
  String? _errorMessage;

  UserProfile? get userProfile => _userProfile;
  List<Badge> get allBadges => _allBadges;
  List<Reward> get allRewards => _allRewards;
  GamificationState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == GamificationState.loading;

  void updateDependencies({
    required GamificationServiceInterface gamificationService,
    required DataServiceInterface dataService,
  }) {
    _gamificationService = gamificationService;
    _dataService = dataService;
  }

  /// MODIFIED: Renamed this method to match what your UI screen is calling.
  Future<void> loadAllData(String userId) async {
    if (_gamificationService == null || _dataService == null) {
      _errorMessage = "Services not initialized.";
      _state = GamificationState.error;
      notifyListeners();
      return;
    }

    _state = GamificationState.loading;
    notifyListeners();

    try {
      final results = await Future.wait([
        _dataService!.getUserProfile(userId: userId),
        _gamificationService!.getPredefinedBadges(),
        _gamificationService!.getPredefinedRewards(),
      ]);

      final profileMap = results[0] as Map<String, dynamic>?;
      if (profileMap != null) {
        _userProfile = UserProfile.fromMap(profileMap);
      } else {
        throw Exception('User profile not found.');
      }

      _allBadges = results[1] as List<Badge>;
      _allRewards = results[2] as List<Reward>;

      _state = GamificationState.success;
      _errorMessage = null;

    } catch (e) {
      _errorMessage = e.toString();
      _state = GamificationState.error;
    } finally {
      notifyListeners();
    }
  }
}