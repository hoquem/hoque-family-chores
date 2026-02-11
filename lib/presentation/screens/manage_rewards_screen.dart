import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/reward_templates.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/points.dart';
import '../providers/riverpod/rewards_notifier.dart';

/// Screen for parents to create, edit, and manage rewards
class ManageRewardsScreen extends ConsumerStatefulWidget {
  final FamilyId familyId;
  final String parentUserId;

  const ManageRewardsScreen({
    Key? key,
    required this.familyId,
    required this.parentUserId,
  }) : super(key: key);

  @override
  ConsumerState<ManageRewardsScreen> createState() => _ManageRewardsScreenState();
}

class _ManageRewardsScreenState extends ConsumerState<ManageRewardsScreen> {
  @override
  Widget build(BuildContext context) {
    final rewardsAsync = ref.watch(rewardsNotifierProvider(widget.familyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rewards'),
      ),
      body: rewardsAsync.when(
        data: (rewards) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rewardsNotifierProvider(widget.familyId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(reward.iconEmoji, style: const TextStyle(fontSize: 24)),
                      backgroundColor: Colors.amber.shade50,
                    ),
                    title: Text(reward.name),
                    subtitle: Text('⭐ ${reward.costAsInt} stars'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editReward(reward),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReward(reward),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReward,
        icon: const Icon(Icons.add),
        label: const Text('Add Reward'),
      ),
    );
  }

  void _createReward() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardFormScreen(
          familyId: widget.familyId,
          parentUserId: widget.parentUserId,
        ),
      ),
    );
  }

  void _editReward(Reward reward) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardFormScreen(
          familyId: widget.familyId,
          parentUserId: widget.parentUserId,
          existingReward: reward,
        ),
      ),
    );
  }

  Future<void> _deleteReward(Reward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reward'),
        content: Text('Are you sure you want to delete "${reward.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(rewardsNotifierProvider(widget.familyId).notifier)
            .deleteReward(widget.familyId, reward.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted: ${reward.name}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Form screen for creating/editing rewards
class RewardFormScreen extends ConsumerStatefulWidget {
  final FamilyId familyId;
  final String parentUserId;
  final Reward? existingReward;

  const RewardFormScreen({
    Key? key,
    required this.familyId,
    required this.parentUserId,
    this.existingReward,
  }) : super(key: key);

  @override
  ConsumerState<RewardFormScreen> createState() => _RewardFormScreenState();
}

class _RewardFormScreenState extends ConsumerState<RewardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _starCostController;
  late TextEditingController _stockController;

  String _selectedEmoji = '🎁';
  RewardType _selectedType = RewardType.privilege;
  bool _isFeatured = false;
  bool _hasStock = false;

  final List<String> _emojiOptions = [
    '🎮', '🍕', '🎬', '📱', '🛒', '🎂', '⏰', '🎁',
    '🍽️', '💷', '🧊', '🍨', '🎯', '🏆', '⭐', '🎉',
  ];

  @override
  void initState() {
    super.initState();
    final reward = widget.existingReward;
    
    _nameController = TextEditingController(text: reward?.name ?? '');
    _descriptionController = TextEditingController(text: reward?.description ?? '');
    _starCostController = TextEditingController(
      text: reward?.costAsInt.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: reward?.stock?.toString() ?? '',
    );

    if (reward != null) {
      _selectedEmoji = reward.iconEmoji;
      _selectedType = reward.type;
      _isFeatured = reward.isFeatured;
      _hasStock = reward.stock != null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _starCostController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReward != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Reward' : 'Create Reward'),
        actions: [
          TextButton(
            onPressed: _saveReward,
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Templates section (only for new rewards)
            if (!isEditing) ...[
              Text(
                'Templates',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: RewardTemplates.all.length,
                  itemBuilder: (context, index) {
                    final template = RewardTemplates.all[index];
                    return Card(
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _loadTemplate(template),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(template.iconEmoji, style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 4),
                              Text(
                                template.name,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 32),
            ],

            // Emoji picker
            Text(
              'Reward Icon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojiOptions.map((emoji) {
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.amber.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Reward Name *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Extra Game Time',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a reward name';
                }
                if (value.trim().length > 50) {
                  return 'Name must be 50 characters or less';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Optional description...',
              ),
              maxLines: 3,
              maxLength: 200,
            ),

            const SizedBox(height: 16),

            // Star cost field
            TextFormField(
              controller: _starCostController,
              decoration: const InputDecoration(
                labelText: 'Star Cost *',
                border: OutlineInputBorder(),
                prefixText: '⭐ ',
                hintText: '50',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a star cost';
                }
                final cost = int.tryParse(value);
                if (cost == null || cost < 1 || cost > 9999) {
                  return 'Enter a valid cost between 1 and 9999';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<RewardType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: RewardType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Stock toggle and field
            SwitchListTile(
              title: const Text('Limited Stock'),
              value: _hasStock,
              onChanged: (value) => setState(() => _hasStock = value),
            ),

            if (_hasStock) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                  hintText: '10',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_hasStock) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock < 0) {
                      return 'Enter a valid stock quantity';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Featured toggle
            SwitchListTile(
              title: const Text('Feature this reward'),
              subtitle: const Text('Shows in featured carousel'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
            ),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _saveReward,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(isEditing ? 'Update Reward' : 'Create Reward'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadTemplate(RewardTemplate template) {
    setState(() {
      _nameController.text = template.name;
      _descriptionController.text = template.description;
      _starCostController.text = template.starCost.toString();
      _selectedEmoji = template.iconEmoji;
      _selectedType = template.type;
      _isFeatured = template.isSpecial;
    });
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final reward = Reward(
      id: widget.existingReward?.id ?? 'reward_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      pointsCost: Points(int.parse(_starCostController.text)),
      iconEmoji: _selectedEmoji,
      type: _selectedType,
      familyId: widget.familyId,
      creatorId: widget.parentUserId,
      createdAt: widget.existingReward?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      stock: _hasStock ? int.tryParse(_stockController.text) : null,
      isFeatured: _isFeatured,
    );

    try {
      if (widget.existingReward != null) {
        await ref
            .read(rewardsNotifierProvider(widget.familyId).notifier)
            .updateReward(reward.id, reward);
      } else {
        await ref
            .read(rewardsNotifierProvider(widget.familyId).notifier)
            .createReward(reward);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingReward != null
                  ? 'Reward updated successfully!'
                  : 'Reward created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save reward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
