// DESIGN.md bans bounce/elastic easing everywhere except the owner-approved
// carve-out: the celebration module (lib/presentation/motion/). This test is
// the carve-out's fence.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overshoot curves appear only inside lib/presentation/motion/', () {
    final banned = RegExp(
        r'\b(elasticOut|elasticIn|bounceOut|bounceIn|easeOutBack|easeInBack)\b');
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.startsWith('lib/presentation/motion/')) continue;
      for (final (i, line) in f.readAsLinesSync().indexed) {
        final code = line.split('//').first; // ignore comments
        if (banned.hasMatch(code)) offenders.add('${f.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty,
        reason: 'Bouncy easing is allowed ONLY in lib/presentation/motion/ '
            '(DESIGN.md carve-out). Found: $offenders');
  });
}
