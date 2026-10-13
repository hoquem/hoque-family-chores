import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// The one bold region a screen may have: a Lagoon panel at the top of the
/// tab (DESIGN.md, "Saturday Morning").
///
/// Everything placed inside inherits the colours that are legible on Lagoon,
/// so callers never pick them by hand:
/// - text and icons are Cream (6.93:1);
/// - filled buttons are Star Gold with Ink text (9.28:1), because the
///   app-wide Marigold manages only 2.73:1 against Lagoon, under the 3:1
///   floor for a control's edge.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Card(
      color: tokens.lagoon,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(
          textTheme: theme.textTheme
              .apply(bodyColor: tokens.cream, displayColor: tokens.cream),
          iconTheme: theme.iconTheme.copyWith(color: tokens.cream),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: tokens.starGold,
              foregroundColor: tokens.ink,
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: tokens.cream),
          child: IconTheme.merge(
            data: IconThemeData(color: tokens.cream),
            child: child,
          ),
        ),
      ),
    );
  }
}
