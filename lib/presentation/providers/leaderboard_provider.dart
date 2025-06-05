// lib/presentation/providers/leaderboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/services/leaderboard_service_interface.dart';

enum LeaderboardState { initial, loading, loaded, error }

class LeaderboardProvider with ChangeNotifier {
  final LeaderboardServiceInterface _leaderboardService;

  LeaderboardProvider(this._leaderboardService);

  LeaderboardState _state = LeaderboardState.initial;
  List<LeaderboardEntry> _entries = [];
  String _errorMessage = '';

  LeaderboardState get state => _state;
  List<LeaderboardEntry> get entries => _entries;
  String get errorMessage => _errorMessage;

  Future<void> fetchLeaderboard() async {
    _state = LeaderboardState.loading;
    notifyListeners();

    try {
      _entries = await _leaderboardService.getLeaderboard();
      _state = LeaderboardState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = LeaderboardState.error;
    }
    notifyListeners();
  }
}