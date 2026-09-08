import 'package:flutter/material.dart';
import '../../domain/entities/chore_guide.dart';
import '../theme/app_tokens.dart';

/// A card that displays helpful tips, motivation, and reasons why completing
/// the chore matters to the child, family, and home.
///
/// Designed to be clean, child-legible, warm, and playful ("The Fridge Door" aesthetic).
class ChoreGuideCard extends StatelessWidget {
  final ChoreGuide guide;
  final VoidCallback? onEditParentTip;

  const ChoreGuideCard({
    super.key,
    required this.guide,
    this.onEditParentTip,
  });

  @override
  Widget build(BuildContext context) {
    if (guide.isEmpty) return const SizedBox.shrink();

    final t = context.tokens;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: t.line, width: 1.5),
      ),
      color: t.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Lightbulb icon + title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.marigold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lightbulb_rounded,
                    size: 22,
                    color: t.marigoldDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mission Guide & Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: t.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'How to crush it and why it matters',
                        style: TextStyle(
                          fontSize: 14,
                          color: t.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Home Tip from Parent (Augmented house information)
            if (guide.parentTip != null && guide.parentTip!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.marigold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: t.marigoldDeep.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: 20,
                          color: t.marigoldDeep,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'HOME NOTE FROM PARENT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: t.ink,
                            ),
                          ),
                        ),
                        if (onEditParentTip != null)
                          InkWell(
                            onTap: onEditParentTip,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 15, color: t.marigoldDeep),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: t.marigoldDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      guide.parentTip!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (onEditParentTip != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onEditParentTip,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: t.marigold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: t.marigold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_home_outlined,
                          size: 18, color: t.marigoldDeep),
                      const SizedBox(width: 8),
                      Text(
                        'Add house note (supplies, bin location, rules)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: t.marigoldDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Motivation / Power Boost
            if (guide.motivation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.starGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: t.starGold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: t.carrotDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'POWER BOOST',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: t.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            guide.motivation,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.ink,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step-by-Step instructions (Clean read-only list)
            if (guide.steps.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'STEPS TO COMPLETE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: t.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              ...guide.steps.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final stepText = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: t.marigold,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$index',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: t.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            stepText,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: t.ink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Why it matters (For You, For Family, For Home)
            if (guide.forYou.isNotEmpty ||
                guide.forFamily.isNotEmpty ||
                guide.forHome.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'WHY THIS HELPS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: t.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              if (guide.forYou.isNotEmpty)
                _WhyRow(
                  emoji: '🌟',
                  label: 'For You',
                  text: guide.forYou,
                  tokens: t,
                ),
              if (guide.forFamily.isNotEmpty)
                _WhyRow(
                  emoji: '🏡',
                  label: 'For Family',
                  text: guide.forFamily,
                  tokens: t,
                ),
              if (guide.forHome.isNotEmpty)
                _WhyRow(
                  emoji: '🛋️',
                  label: 'For Home',
                  text: guide.forHome,
                  tokens: t,
                ),
            ],

            // Learning takeaway / Superpower
            if (guide.takeaway.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.sprout.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: t.sprout.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: t.sproutDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUPERPOWER TAKEAWAY',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: t.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            guide.takeaway,
                            style: TextStyle(
                              fontSize: 14,
                              color: t.ink,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WhyRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String text;
  final CustomColors tokens;

  const _WhyRow({
    required this.emoji,
    required this.label,
    required this.text,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: tokens.ink,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
