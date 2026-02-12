import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import '../../domain/entities/task.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../providers/riverpod/pending_approvals_notifier.dart';

/// Screen for reviewing and approving/rejecting pending task completions
class TaskApprovalScreen extends ConsumerStatefulWidget {
  final FamilyId familyId;
  final UserId parentId;
  final Task? initialTask;

  const TaskApprovalScreen({
    super.key,
    required this.familyId,
    required this.parentId,
    this.initialTask,
  });

  @override
  ConsumerState<TaskApprovalScreen> createState() => _TaskApprovalScreenState();
}

class _TaskApprovalScreenState extends ConsumerState<TaskApprovalScreen> {
  late ConfettiController _confettiController;
  int _currentIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingApprovalsAsync = ref.watch(
      pendingApprovalsNotifierProvider(widget.familyId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          pendingApprovalsAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return _buildEmptyState();
              }

              // Find initial task index if provided
              if (widget.initialTask != null && _currentIndex == 0) {
                final index = tasks.indexWhere(
                  (t) => t.id == widget.initialTask!.id,
                );
                if (index >= 0) {
                  _currentIndex = index;
                }
              }

              // Ensure index is valid
              if (_currentIndex >= tasks.length) {
                _currentIndex = tasks.length - 1;
              }

              return _buildApprovalCard(tasks[_currentIndex], tasks.length);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFB300),
                Color(0xFF6750A4),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No quests awaiting approval',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load approvals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Task task, int totalCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator if multiple tasks
          if (totalCount > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentIndex + 1} of $totalCount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6750A4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Photo preview
          if (task.photoUrl != null)
            _buildPhotoPreview(task.photoUrl!)
          else
            _buildPhotoPlaceholder(),

          const SizedBox(height: 16),

          // Quest title
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),

          const SizedBox(height: 8),

          // Quest description
          if (task.description.isNotEmpty)
            Text(
              task.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF49454F),
              ),
            ),

          const SizedBox(height: 16),

          // AI Assessment card
          if (task.aiRating != null) _buildAIAssessmentCard(task.aiRating!),

          const SizedBox(height: 16),

          // Metadata
          _buildMetadata(task),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildApproveButton(task),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRejectButton(task),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview(String photoUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenPhoto(photoUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0x1A6750A4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 64),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('Photo unavailable', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssessmentCard(AIRating aiRating) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1A6750A4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy, color: Color(0xFF6750A4), size: 20),
              SizedBox(width: 8),
              Text(
                'AI Assessment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6750A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (aiRating.score / 2).round()
                      ? Icons.star
                      : Icons.star_border,
                  color: const Color(0xFFFFB300),
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '${aiRating.score.toStringAsFixed(1)}/10',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6750A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aiRating.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.submittedBy != null)
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF79747E)),
              const SizedBox(width: 4),
              Text(
                'Submitted by: ${task.submittedBy!.value}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF79747E),
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
        if (task.submittedAt != null)
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF79747E)),
              const SizedBox(width: 4),
              Text(
                _formatTimeAgo(task.submittedAt!),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF79747E),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildApproveButton(Task task) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _handleApprove(task),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 2,
      ),
      child: _isProcessing
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Column(
              children: [
                const Text(
                  '✅ Approve',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${task.points.value} stars',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
    );
  }

  Widget _buildRejectButton(Task task) {
    return OutlinedButton(
      onPressed: _isProcessing ? null : () => _showRejectDialog(task),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF49454F),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: const BorderSide(color: Color(0xFF79747E), width: 2),
      ),
      child: const Column(
        children: [
          Text(
            '❌ Reject',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Send feedback',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(Task task) async {
    setState(() => _isProcessing = true);

    try {
      await ref.read(pendingApprovalsNotifierProvider(widget.familyId).notifier).approveTask(
            taskId: task.id,
            approverId: widget.parentId,
            familyId: widget.familyId,
          );

      // Show confetti
      _confettiController.play();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quest approved! ${task.assignedToId?.value ?? 'Child'} earned ${task.points.value} stars ⭐'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Wait for confetti, then proceed
      await Future.delayed(const Duration(seconds: 2));

      // Move to next task or exit
      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showRejectDialog(Task task) async {
    final reasonController = TextEditingController();
    String? selectedReason;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Send Feedback (Optional) 💙',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Suggestions:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSuggestionChip(
                        'Please try again',
                        selectedReason,
                        (value) => setModalState(() => selectedReason = value),
                      ),
                      _buildSuggestionChip(
                        'Check the corners',
                        selectedReason,
                        (value) => setModalState(() => selectedReason = value),
                      ),
                      _buildSuggestionChip(
                        'Photo needs better lighting',
                        selectedReason,
                        (value) => setModalState(() => selectedReason = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add your own message',
                      hintText: 'Be kind and specific...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your feedback will help them improve! 🌟',
                    style: TextStyle(fontSize: 12, color: Color(0xFF79747E)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6750A4),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Send & Close'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );

    if (result == true && mounted) {
      final reason = reasonController.text.isEmpty
          ? selectedReason
          : reasonController.text;

      await _handleReject(task, reason);
    }

    reasonController.dispose();
  }

  Widget _buildSuggestionChip(
    String label,
    String? selectedReason,
    Function(String?) onSelected,
  ) {
    final isSelected = selectedReason == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? label : null);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF6750A4),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF49454F),
      ),
    );
  }

  Future<void> _handleReject(Task task, String? reason) async {
    setState(() => _isProcessing = true);

    try {
      await ref.read(pendingApprovalsNotifierProvider(widget.familyId).notifier).rejectTask(
            taskId: task.id,
            reason: reason,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback sent to ${task.assignedToId?.value ?? 'child'} 💙'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullScreenPhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
