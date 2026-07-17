import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A task's before and after photos, one at a time, tap to swap.
///
/// Tap-to-toggle rather than a slider: a parent clearing an approval queue in
/// seconds should not have to drag anything, and a slider implies the two
/// frames are aligned — handheld shots taken minutes apart never are. Showing
/// one at a time also gives each photo the full width, which matters at 320pt.
class BeforeAfterView extends StatefulWidget {
  const BeforeAfterView({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  final String beforeUrl;
  final String afterUrl;

  @override
  State<BeforeAfterView> createState() => _BeforeAfterViewState();
}

class _BeforeAfterViewState extends State<BeforeAfterView> {
  bool _showingAfter = true;

  /// Starts on the after: it is what the parent is being asked to judge. The
  /// before is context, one tap away.
  String get _url => _showingAfter ? widget.afterUrl : widget.beforeUrl;
  String get _label => _showingAfter ? 'After' : 'Before';
  String get _otherLabel => _showingAfter ? 'Before' : 'After';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Semantics(
      button: true,
      label: 'Task photo, $_label',
      hint: 'Tap to see the $_otherLabel photo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => setState(() => _showingAfter = !_showingAfter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // No AnimatedSwitcher: a cross-fade between two photos of
                    // the same room reads as a glitch rather than a reveal.
                    // The label change carries the swap.
                    CachedNetworkImage(
                      key: ValueKey(_url),
                      imageUrl: _url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => ColoredBox(
                        color: t.line,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      // Explicit, because a silent blank on the screen where a
                      // parent decides whether their child did a chore is the
                      // worst possible ambiguity.
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: t.line,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: t.inkSoft, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              "Couldn't load this photo",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: t.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Chip(label: _label),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the photo to see the $_otherLabel',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Before/After marker sitting on the photo.
///
/// Ink on cream rather than a translucent overlay: the label has to stay
/// readable over whatever the photo happens to be.
class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: t.ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}
