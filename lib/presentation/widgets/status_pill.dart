import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

/// The alpha the pill tints its background with. Matches DESIGN.md §5 and is
/// asserted by ``test/presentation/theme/token_contrast_test.dart``.
const double kStatusPillTint = 0.12;

/// A task status rendered as DESIGN.md's status pill: a tint of the status
/// colour, the status icon in its AA-safe deep tone, and an **ink** label.
///
/// The label is ink rather than the status colour on purpose. A full-saturation
/// status colour on a 12% tint of itself cannot reach WCAG AA — amber managed
/// 1.84:1 against the 4.5:1 floor PRODUCT.md requires — and these pills are
/// read by children who are still learning to read. Identity still comes from
/// the icon and the word (the Status-Never-Alone Rule); the hue conveys
/// aliveness through the tint and icon, which is what DESIGN.md asks of it.
///
/// Centralising the mapping here is what stops the five call sites from each
/// re-deriving a different colour, icon, or size for the same state.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, required this.label});

  final TaskStatus status;

  /// The word shown next to the icon. Supplied by the caller so existing
  /// copy stays put; DESIGN.md's shorter wording ("Waiting", "Done") is a
  /// separate copy pass.
  final String label;

  /// The status colour, which carries the background tint.
  Color _tone(CustomColors t) => switch (status) {
        TaskStatus.available => t.inkSoft, // neutral: not yet alive
        TaskStatus.assigned => t.carrot,
        TaskStatus.pendingApproval => t.amberWarn,
        TaskStatus.completed => t.sprout,
        TaskStatus.needsRevision => t.brick,
      };

  /// The deep sibling, dark enough to clear 3:1 as an icon on [_tone]'s tint.
  Color _iconTone(CustomColors t) => switch (status) {
        TaskStatus.available => t.inkSoft,
        TaskStatus.assigned => t.carrotDeep,
        TaskStatus.pendingApproval => t.amberWarnDeep,
        TaskStatus.completed => t.sproutDeep,
        TaskStatus.needsRevision => t.brickDeep,
      };

  IconData get _icon => switch (status) {
        TaskStatus.available => Icons.circle_outlined,
        TaskStatus.assigned => Icons.play_circle,
        TaskStatus.pendingApproval => Icons.hourglass_top,
        TaskStatus.completed => Icons.check_circle,
        TaskStatus.needsRevision => Icons.undo,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: 'Status: $label',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _tone(t).withValues(alpha: kStatusPillTint),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: _iconTone(t)),
            const SizedBox(width: 6),
            // Flexible, not a hardcoded newline: the pill may sit in a narrow
            // column and must degrade by ellipsis rather than by overflow.
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // The 14px Floor Rule. Never below this: emerging readers.
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
