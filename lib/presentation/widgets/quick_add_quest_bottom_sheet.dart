import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/quick_add_quest_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Shows the Quick Add Quest bottom sheet
void showQuickAddQuestBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuickAddQuestBottomSheet(),
  );
}

/// Quick Add Quest bottom sheet widget
class QuickAddQuestBottomSheet extends ConsumerStatefulWidget {
  const QuickAddQuestBottomSheet({super.key});

  @override
  ConsumerState<QuickAddQuestBottomSheet> createState() => _QuickAddQuestBottomSheetState();
}

class _QuickAddQuestBottomSheetState extends ConsumerState<QuickAddQuestBottomSheet> {
  final _logger = AppLogger();
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Reset form when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quickAddQuestNotifierProvider.notifier).reset();
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (currentUser == null || familyId == null) {
      _logger.w('QuickAddQuestBottomSheet: User or family ID is null');
      return;
    }

    final notifier = ref.read(quickAddQuestNotifierProvider.notifier);
    final success = await notifier.createQuest(
      familyId: familyId,
      createdById: currentUser.id,
    );

    if (success && mounted) {
      // Refresh the task list
      ref.read(taskListNotifierProvider(familyId).notifier).refresh();
      
      // Close the bottom sheet
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quest added! ⭐'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFFFB300),
        ),
      );
    }
  }

  Widget _buildTemplateChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: questTemplates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final template = questTemplates[index];
          return ActionChip(
            label: Text('${template.emoji} ${template.title} (${template.stars}⭐)'),
            onPressed: () {
              ref.read(quickAddQuestNotifierProvider.notifier).applyTemplate(template);
              _titleController.text = template.title;
            },
          );
        },
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      autofocus: true,
      maxLength: 50,
      decoration: const InputDecoration(
        labelText: 'Quest title',
        hintText: 'What needs to be done?',
        border: OutlineInputBorder(),
        counterText: '',
      ),
      onChanged: (value) {
        ref.read(quickAddQuestNotifierProvider.notifier).updateTitle(value);
      },
      onSubmitted: (_) {
        if (_canSubmit()) {
          _handleSubmit();
        }
      },
    );
  }

  Widget _buildStarSelector() {
    final state = ref.watch(quickAddQuestNotifierProvider);
    final starOptions = [3, 5, 8, 10];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stars',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: starOptions.map((stars) {
            final isSelected = state.stars == stars;
            return ChoiceChip(
              label: Text('$stars'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(quickAddQuestNotifierProvider.notifier).updateStars(stars);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssigneeSelector(FamilyId familyId) {
    final membersAsync = ref.watch(familyMembersNotifierProvider(familyId));
    final state = ref.watch(quickAddQuestNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign to',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        membersAsync.when(
          data: (members) {
            if (members.isEmpty) {
              return const Text('No family members available');
            }
            return Wrap(
              spacing: 8,
              children: members.map((member) {
                final isSelected = state.assignedToId == member.id;
                return ChoiceChip(
                  label: Text(member.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(quickAddQuestNotifierProvider.notifier).updateAssignee(member.id);
                    }
                  },
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error loading members: $error'),
        ),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    final state = ref.watch(quickAddQuestNotifierProvider);
    final now = DateTime.now();
    
    final dueDateOptions = [
      ('Today 6pm', DateTime(now.year, now.month, now.day, 18, 0)),
      ('Today 8pm', DateTime(now.year, now.month, now.day, 20, 0)),
      ('Tomorrow', DateTime(now.year, now.month, now.day + 1, 18, 0)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: dueDateOptions.map((option) {
            final label = option.$1;
            final date = option.$2;
            final isSelected = state.dueDate?.isAtSameMomentAs(date) ?? false;
            
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(quickAddQuestNotifierProvider.notifier).updateDueDate(
                  selected ? date : null,
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _canSubmit() {
    final state = ref.read(quickAddQuestNotifierProvider);
    return state.title.trim().length >= 3 &&
           state.title.length <= 50 &&
           state.assignedToId != null &&
           !state.isSubmitting;
  }

  Widget _buildSubmitButton() {
    final state = ref.watch(quickAddQuestNotifierProvider);
    final canSubmit = _canSubmit();

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: canSubmit ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB300),
          foregroundColor: const Color(0xFF6750A4),
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.38),
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6750A4),
                ),
              )
            : const Text(
                'Add Quest',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    final state = ref.watch(quickAddQuestNotifierProvider);
    
    if (state.errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (familyId == null) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('Please log in and join a family to create quests.'),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Quick Add Quest',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Template chips
            _buildTemplateChips(),
            const SizedBox(height: 16),
            
            // Title input
            _buildTitleInput(),
            const SizedBox(height: 16),
            
            // Star selector
            _buildStarSelector(),
            const SizedBox(height: 16),
            
            // Assignee selector
            _buildAssigneeSelector(familyId),
            const SizedBox(height: 16),
            
            // Due date selector
            _buildDueDateSelector(),
            const SizedBox(height: 16),
            
            // Error message
            _buildErrorMessage(),
            const SizedBox(height: 16),
            
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
}
