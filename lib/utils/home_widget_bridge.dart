import 'package:home_widget/home_widget.dart';
import 'package:hoque_family_chores/domain/usecases/home/build_home_widget_data_usecase.dart';

/// App group identifier used to share widget data between the Flutter app and
/// the iOS widget extension. Matches the App Groups capability configured in
/// Xcode.
const String _kAppGroupId = 'group.com.hoque.hoqueFamilyChores';

/// Names used to identify this widget on iOS and Android.
const String _kWidgetName = 'ChoresStarWidget';

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
      name: _kWidgetName,
      androidName: _kWidgetName,
      iOSName: _kWidgetName,
    );
  }
}
