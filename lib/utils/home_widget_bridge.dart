import 'package:home_widget/home_widget.dart';
import 'package:hoque_family_chores/domain/usecases/home/build_home_widget_data_usecase.dart';

/// App group identifier used to share widget data between the Flutter app and
/// the iOS widget extension. Matches the App Groups capability configured in
/// Xcode.
const String _kAppGroupId = 'group.com.hoque.hoqueFamilyChores';

/// iOS identifies the widget by its WidgetKit ``kind`` string.
const String _kIOSWidgetKind = 'ChoresStarWidget';

/// Android identifies the widget by its AppWidgetProvider class, which
/// home_widget resolves as ``Class.forName("$packageName.$androidName")``.
/// It is NOT the same string as the iOS kind — passing the kind here throws
/// ClassNotFoundException and the widget stops refreshing until its 24h
/// updatePeriodMillis elapses. Pinned by home_widget_names_consistency_test.
const String _kAndroidProviderName = 'ChoresStarWidgetProvider';

/// Bridge between Flutter domain state and the native home-screen widget.
///
/// This abstraction exists so tests and the presentation layer do not depend
/// directly on the `home_widget` package's static API. Production code uses
/// [HomeWidgetBridgeImpl]; tests inject a no-op or spy implementation.
abstract class HomeWidgetBridge {
  /// Initializes the bridge (e.g., sets the iOS App Group).
  Future<void> initialize();

  /// Saves [data] to the shared container and requests a widget update.
  Future<void> update(HomeWidgetData data);
}

/// Production implementation backed by the `home_widget` package.
class HomeWidgetBridgeImpl implements HomeWidgetBridge {
  /// The WidgetKit kind declared in ``ChoresStarWidget.swift``.
  static const String iOSWidgetKind = _kIOSWidgetKind;

  /// The AppWidgetProvider class declared in ``AndroidManifest.xml``.
  static const String androidProviderName = _kAndroidProviderName;

  @override
  Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_kAppGroupId);
  }

  @override
  Future<void> update(HomeWidgetData data) async {
    await HomeWidget.saveWidgetData<String>('greeting', data.greeting);
    await HomeWidget.saveWidgetData<int>(
      'currentStreakDays',
      data.currentStreakDays,
    );
    await HomeWidget.saveWidgetData<String>(
      'missionTitles',
      data.missionTitles.join('\n'),
    );
    await HomeWidget.saveWidgetData<int>(
      'pendingApprovalCount',
      data.pendingApprovalCount,
    );

    await HomeWidget.updateWidget(
      androidName: _kAndroidProviderName,
      iOSName: _kIOSWidgetKind,
    );
  }
}
