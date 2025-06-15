// lib/presentation/providers/leaderboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

enum LeaderboardState { initial, loading, loaded, error }

class LeaderboardProvider with ChangeNotifier {
  final LeaderboardServiceInterface _leaderboardService;
  final _logger = AppLogger();

  LeaderboardProvider(this._leaderboardService);

  LeaderboardState _state = LeaderboardState.initial;
  List<LeaderboardEntry> _entries = [];
  String _errorMessage = '';

  LeaderboardState get state => _state;
  List<LeaderboardEntry> get entries => _entries;
  String get errorMessage => _errorMessage;

  Future<void> fetchLeaderboard({required String familyId}) async {
    _state = LeaderboardState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _entries = await _leaderboardService.getLeaderboard(familyId: familyId);
      _state = LeaderboardState.loaded;
    } catch (e, s) {
      _logger.e('Error fetching leaderboard: $e', error: e, stackTrace: s);
      _errorMessage = 'Failed to fetch leaderboard';
      _state = LeaderboardState.error;
    }
    notifyListeners();
  }
}
