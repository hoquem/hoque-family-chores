import 'package:flutter/material.dart';
import '../../utils/logger.dart';

/// Service for handling deep links from notifications
class DeepLinkHandler {
  final AppLogger _logger = AppLogger();
  final GlobalKey<NavigatorState>? navigatorKey;

  DeepLinkHandler({this.navigatorKey});

  /// Handle deep link navigation
  Future<void> handleDeepLink(String url) async {
    try {
      _logger.i('[DeepLink] Handling: $url');

      final uri = Uri.parse(url);
      final path = uri.host; // e.g., "quest"
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      final params = uri.queryParameters;

      final navigator = navigatorKey?.currentState;
      if (navigator == null) {
        _logger.w('[DeepLink] Navigator not available');
        return;
      }

      switch (path) {
        case 'home':
          _logger.i('[DeepLink] Navigating to home');
          navigator.pushReplacementNamed('/');
          break;

        case 'quest':
          if (id != null) {
            _logger.i('[DeepLink] Navigating to quest: $id');
            navigator.pushNamed('/quest/$id');
          }
          break;

        case 'approvals':
          _logger.i('[DeepLink] Navigating to approvals');
          navigator.pushNamed('/approvals');
          break;

        case 'profile':
          final userId = uri.pathSegments.isNotEmpty
              ? uri.pathSegments[0]
              : 'me';
          _logger.i('[DeepLink] Navigating to profile: $userId');
          navigator.pushNamed('/profile/$userId');

          // Handle celebration modals
          if (params['celebrate'] == 'level_up') {
            _logger.i('[DeepLink] Showing level up celebration');
            await Future.delayed(const Duration(milliseconds: 500));
            // TODO: Show level up modal
          } else if (params['celebrate'] == 'streak') {
            _logger.i('[DeepLink] Showing streak celebration');
            await Future.delayed(const Duration(milliseconds: 500));
            // TODO: Show streak modal
          }
          break;

        case 'reward':
          if (id != null) {
            _logger.i('[DeepLink] Navigating to reward: $id');
            navigator.pushNamed('/reward/$id');
          }
          break;

        default:
          _logger.w('[DeepLink] Unknown path: $path');
          navigator.pushReplacementNamed('/');
      }
    } catch (e, stackTrace) {
      _logger.e(
        '[DeepLink] Failed to handle deep link',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parse notification data and handle deep link
  Future<void> handleNotificationData(Map<String, dynamic> data) async {
    final deepLink = data['deepLink'] as String?;
    final questId = data['questId'] as String?;
    final userId = data['userId'] as String?;

    if (deepLink != null) {
      await handleDeepLink(deepLink);
    } else if (questId != null) {
      // Fallback: construct deep link from data
      await handleDeepLink('choresapp://quest/$questId');
    } else if (userId != null) {
      await handleDeepLink('choresapp://profile/$userId');
    } else {
      // Default: go to home
      await handleDeepLink('choresapp://home');
    }
  }
}
