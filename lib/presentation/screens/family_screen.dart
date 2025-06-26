import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';
import 'package:hoque_family_chores/presentation/providers/leaderboard_provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _logger.i('FamilyScreen: initState called');
    // Don't call _refreshData here as context might not be ready
    _logger.d('FamilyScreen: initState completed');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.d('FamilyScreen: didChangeDependencies called');
    // Call refresh here when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.d('FamilyScreen: Post frame callback - calling refresh');
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    _logger.d('FamilyScreen: Refreshing data');
    
    try {
      final leaderboardProvider = context.read<LeaderboardProvider>();
      final authProvider = context.read<AuthProviderBase>();
      final familyId = authProvider.userFamilyId;

      _logger.d('FamilyScreen: Got familyId: $familyId');
      _logger.d('FamilyScreen: LeaderboardProvider state: ${leaderboardProvider.state}');
      _logger.d('FamilyScreen: AuthProvider type: ${authProvider.runtimeType}');

      if (familyId != null) {
        _logger.d('FamilyScreen: Calling fetchLeaderboard with familyId: $familyId');
        await leaderboardProvider.fetchLeaderboard(familyId: familyId);
        _logger.d('FamilyScreen: fetchLeaderboard completed');
      } else {
        _logger.w('FamilyScreen: familyId is null, cannot fetch leaderboard');
      }
    } catch (e, stackTrace) {
      _logger.e('FamilyScreen: Error in _refreshData: $e', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('FamilyScreen: Building screen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _logger.d('FamilyScreen: Manual refresh triggered');
              _refreshData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Family Leaderboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                _logger.d('FamilyScreen: Building LeaderboardWidget'),
                const LeaderboardWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
