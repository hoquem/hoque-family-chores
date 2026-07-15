import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottom_nav_notifier.g.dart';

/// Currently selected bottom-navigation tab.
///
/// Lives in a provider so any screen can send the user to another tab,
/// e.g. the Home approval card opening the Tasks tab.
@riverpod
class BottomNavIndexNotifier extends _$BottomNavIndexNotifier {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}
