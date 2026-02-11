import 'package:flutter/material.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:intl/intl.dart';

class QuestCard extends StatelessWidget {
  final Task quest;
  final User? assignee;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final bool isCurrentUserQuest;
  final bool isParent;

  const QuestCard({
    super.key,
    required this.quest,
    this.assignee,
    this.onTap,
    this.onComplete,
    this.isCurrentUserQuest = false,
    this.isParent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final isOverdue = quest.isOverdue;
    final canComplete = (isCurrentUserQuest || isParent) && !isCompleted;

    return Card(
      elevation: isCompleted ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isOverdue && !isCompleted
            ? const BorderSide(color: Color(0xFFF44336), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title + Action/Status
                Row(
                  children: [
                    // Quest emoji/icon (if available from tags)
                    if (quest.tags.isNotEmpty) ...[
                      Text(
                        _getQuestEmoji(quest.tags.first),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Title
                    Expanded(
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status indicator
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      )
                    else if (canComplete)
                      InkWell(
                        onTap: onComplete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'COMPLETE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Stars
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted
                          ? '${quest.points.value} ${quest.points.value == 1 ? 'star' : 'stars'} earned'
                          : '${quest.points.value} ${quest.points.value == 1 ? 'star' : 'stars'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCompleted ? Colors.grey : const Color(0xFFFFB300),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 3: Metadata
                Row(
                  children: [
                    // Assignee
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      assignee?.name ?? 'Anyone',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    // Deadline or completion time
                    Icon(
                      isCompleted ? Icons.check : Icons.schedule,
                      size: 14,
                      color: isOverdue && !isCompleted
                          ? const Color(0xFFF44336)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted
                          ? 'Done at ${_formatTime(quest.completedAt!)}'
                          : 'Before ${_formatTime(quest.dueDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue && !isCompleted
                            ? const Color(0xFFF44336)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                // Overdue indicator
                if (isOverdue && !isCompleted) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  String _getQuestEmoji(String tag) {
    // Map common tags to emojis
    final emojiMap = {
      'cleaning': '🧹',
      'dishes': '🍽️',
      'trash': '🗑️',
      'laundry': '🧺',
      'garden': '🪴',
      'pet': '🐕',
      'homework': '📚',
      'exercise': '🏃',
      'cooking': '🍳',
      'bedroom': '🛏️',
    };
    return emojiMap[tag.toLowerCase()] ?? '✅';
  }
}
