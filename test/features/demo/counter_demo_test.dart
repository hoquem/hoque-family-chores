// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/the_demo_app_is_running.dart';
import './step/i_see_text.dart';
import './step/i_tap_the_increment_button.dart';

void main() {
  group('''Counter Demo''', () {
    testWidgets('''Initial counter value is zero''', (tester) async {
      await theDemoAppIsRunning(tester);
      await iSeeText(tester, '0');
    });
    testWidgets('''Increment counter''', (tester) async {
      await theDemoAppIsRunning(tester);
      await iTapTheIncrementButton(tester);
      await iSeeText(tester, '1');
    });
    testWidgets('''Increment counter multiple times''', (tester) async {
      await theDemoAppIsRunning(tester);
      await iTapTheIncrementButton(tester);
      await iTapTheIncrementButton(tester);
      await iTapTheIncrementButton(tester);
      await iSeeText(tester, '3');
    });
  });
}
