// lib/presentation/providers/leaderboard_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';

enum LeaderboardState { initial, loading, loaded, error }

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardServiceInterface _leaderboardService;
  final _logger = AppLogger();

  List<LeaderboardEntry> _entries = [];
  LeaderboardState _state = LeaderboardState.initial;
  String _errorMessage = '';

  LeaderboardProvider({required LeaderboardServiceInterface leaderboardService})
      : _leaderboardService = leaderboardService {
    _logger.i('LeaderboardProvider: Constructor called');
    _logger.d('LeaderboardProvider: Service type: ${leaderboardService.runtimeType}');
  }

  List<LeaderboardEntry> get entries => _entries;
  LeaderboardState get state => _state;
  String get errorMessage => _errorMessage;

  Future<void> fetchLeaderboard({required String familyId}) async {
    _logger.d('LeaderboardProvider: fetchLeaderboard called with familyId: $familyId');
    _logger.d('LeaderboardProvider: Current state: $_state');
    _logger.d('LeaderboardProvider: Current entries count: ${_entries.length}');
    
    _state = LeaderboardState.loading;
    _errorMessage = '';
    _logger.d('LeaderboardProvider: State changed to loading');
    notifyListeners();

    try {
      _logger.d('LeaderboardProvider: Calling leaderboard service...');
      _logger.d('LeaderboardProvider: Service instance: ${_leaderboardService.runtimeType}');
      
      final startTime = DateTime.now();
      _entries = await _leaderboardService.getLeaderboard(familyId: familyId);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      _logger.d('LeaderboardProvider: Service returned ${_entries.length} entries in ${duration.inMilliseconds}ms');
      
      if (_entries.isNotEmpty) {
        _logger.d('LeaderboardProvider: First entry: ${_entries.first.member.name} with ${_entries.first.points} points');
        _logger.d('LeaderboardProvider: All entries: ${_entries.map((e) => '${e.member.name}(${e.points})').toList()}');
      } else {
        _logger.w('LeaderboardProvider: No entries returned from service');
      }
      
      _state = LeaderboardState.loaded;
      _logger.i('LeaderboardProvider: Successfully loaded leaderboard with ${_entries.length} entries');
    } catch (e, s) {
      _logger.e('LeaderboardProvider: Error fetching leaderboard: $e', error: e, stackTrace: s);
      _errorMessage = 'Failed to fetch leaderboard';
      _state = LeaderboardState.error;
    }
    
    _logger.d('LeaderboardProvider: Final state: $_state, entries: ${_entries.length}');
    notifyListeners();
  }
}
