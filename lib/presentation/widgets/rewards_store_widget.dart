// lib/presentation/widgets/rewards_store_widget.dart
import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/gamification_service.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class RewardsStoreWidget extends StatefulWidget {
  final UserProfile userProfile;
  final List<Reward> availableRewards;
  final List<Reward> redeemedRewards;
  final Function(Reward)? onRewardTap;
  final Function(Reward)? onRewardRedeem;
  final bool showPurchaseAnimation;
  final Reward? newlyPurchasedReward;

  const RewardsStoreWidget({
    Key? key,
    required this.userProfile,
    required this.availableRewards,
    required this.redeemedRewards,
    this.onRewardTap,
    this.onRewardRedeem,
    this.showPurchaseAnimation = false,
    this.newlyPurchasedReward,
  }) : super(key: key);

  @override
  State<RewardsStoreWidget> createState() => _RewardsStoreWidgetState();
}

class _RewardsStoreWidgetState extends State<RewardsStoreWidget> with TickerProviderStateMixin {
  RewardCategory? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 1000);
  int _maxRewardPrice = 1000;
  bool _showOnlyAffordable = false;
  bool _showRedemptionHistory = false;
  
  late AnimationController _gridAnimationController;
  late AnimationController _purchaseAnimationController;
  late Animation<double> _purchaseScaleAnimation;
  late Animation<double> _purchaseRotateAnimation;
  late Animation<double> _purchaseShineAnimation;
  late Animation<double> _confettiAnimation;
  
  final List<AnimationController> _itemAnimationControllers = [];
  final List<Animation<double>> _itemAnimations = [];
  final GlobalKey _newRewardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Find the maximum reward price for the price filter
    if (widget.availableRewards.isNotEmpty) {
      _maxRewardPrice = widget.availableRewards
          .map((r) => r.pointsCost)
          .reduce((a, b) => a > b ? a : b);
      _priceRange = RangeValues(0, _maxRewardPrice.toDouble());
    }
    
    // Grid animation controller
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Purchase animation controller
    _purchaseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _purchaseScaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _purchaseAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );
    
    _purchaseRotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _purchaseAnimationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    
    _purchaseShineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _purchaseAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    _confettiAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _purchaseAnimationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Start grid animation
    _gridAnimationController.forward();
    
    // If showing purchase animation, start it
    if (widget.showPurchaseAnimation && widget.newlyPurchasedReward != null) {
      _purchaseAnimationController.forward();
    }
    
    // Initialize item animations after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeItemAnimations();
    });
  }
  
  void _initializeItemAnimations() {
    // Clear previous controllers
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    _itemAnimationControllers.clear();
    _itemAnimations.clear();
    
    // Create new controllers for each reward
    final filteredRewards = _getFilteredRewards();
    for (int i = 0; i < filteredRewards.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
      
      _itemAnimationControllers.add(controller);
      _itemAnimations.add(animation);
      
      // Stagger the animations
      Future.delayed(Duration(milliseconds: 50 * i), () {
        if (mounted) {
          controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(RewardsStoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If rewards changed, reinitialize animations
    if (oldWidget.availableRewards.length != widget.availableRewards.length ||
        oldWidget.redeemedRewards.length != widget.redeemedRewards.length) {
      _initializeItemAnimations();
    }
    
    // If showing new purchase animation
    if (widget.showPurchaseAnimation && 
        widget.newlyPurchasedReward != null && 
        (oldWidget.newlyPurchasedReward?.id != widget.newlyPurchasedReward?.id)) {
      _purchaseAnimationController.reset();
      _purchaseAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _purchaseAnimationController.dispose();
    for (var controller in _itemAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Reward> _getFilteredRewards() {
    if (_showRedemptionHistory) {
      return widget.redeemedRewards;
    }
    
    return widget.availableRewards.where((reward) {
      // Filter by category
      if (_selectedCategory != null && reward.category != _selectedCategory) {
        return false;
      }
      
      // Filter by price range
      if (reward.pointsCost < _priceRange.start || reward.pointsCost > _priceRange.end) {
        return false;
      }
      
      // Filter by affordability
      if (_showOnlyAffordable && reward.pointsCost > widget.userProfile.totalPoints) {
        return false;
      }
      
      return true;
    }).toList();
  }

  bool _canAffordReward(Reward reward) {
    return widget.userProfile.totalPoints >= reward.pointsCost;
  }

  // Get reward redemption date if available
  String _getRewardRedemptionDate(Reward reward) {
    final redeemedReward = widget.redeemedRewards.firstWhere(
      (r) => r.id == reward.id,
      orElse: () => reward,
    );
    
    if (redeemedReward.redeemedAt != null) {
      return '${redeemedReward.redeemedAt!.day}/${redeemedReward.redeemedAt!.month}/${redeemedReward.redeemedAt!.year}';
    }
    return 'Not redeemed yet';
  }

  @override
  Widget build(BuildContext context) {
    final filteredRewards = _getFilteredRewards();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Points balance card
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildPointsBalanceCard(),
        ),
        
        // Filter options
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Toggle between store and history
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Rewards Store'),
                    icon: Icon(Icons.store),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Redemption History'),
                    icon: Icon(Icons.history),
                  ),
                ],
                selected: {_showRedemptionHistory},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _showRedemptionHistory = newSelection.first;
                    _initializeItemAnimations();
                  });
                },
              ),
              const Spacer(),
              if (!_showRedemptionHistory)
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterDialog(context),
                  tooltip: 'Filter rewards',
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Category filter chips (only show in store mode)
        if (!_showRedemptionHistory)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                        _initializeItemAnimations();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...RewardCategory.values.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(category.displayName),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : null;
                            _initializeItemAnimations();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Status text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            _showRedemptionHistory
                ? 'Redemption History (${widget.redeemedRewards.length})'
                : 'Available Rewards (${filteredRewards.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Rewards grid
        Expanded(
          child: AnimatedBuilder(
            animation: _gridAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _gridAnimationController.value,
                child: child,
              );
            },
            child: filteredRewards.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredRewards.length,
                    itemBuilder: (context, index) {
                      final reward = filteredRewards[index];
                      final isAffordable = _canAffordReward(reward);
                      final isRedeemed = _showRedemptionHistory;
                      final isNewlyPurchased = widget.newlyPurchasedReward?.id == reward.id;
                      
                      // Use item animation if available
                      Widget rewardItem = _buildRewardItem(reward, isAffordable, isRedeemed);
                      if (index < _itemAnimations.length) {
                        rewardItem = AnimatedBuilder(
                          animation: _itemAnimations[index],
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _itemAnimations[index].value,
                              child: Opacity(
                                opacity: _itemAnimations[index].value,
                                child: child,
                              ),
                            );
                          },
                          child: rewardItem,
                        );
                      }
                      
                      // Apply purchase animation if this is the newly purchased reward
                      if (isNewlyPurchased && widget.showPurchaseAnimation) {
                        return AnimatedBuilder(
                          animation: _purchaseAnimationController,
                          builder: (context, child) {
                            return Stack(
                              key: _newRewardKey,
                              children: [
                                Transform.scale(
                                  scale: _purchaseScaleAnimation.value,
                                  child: Transform.rotate(
                                    angle: _purchaseRotateAnimation.value,
                                    child: Stack(
                                      children: [
                                        child!,
                                        // Shine effect
                                        Positioned.fill(
                                          child: ClipRect(
                                            child: Transform.translate(
                                              offset: Offset(
                                                _purchaseShineAnimation.value * 100,
                                                0,
                                              ),
                                              child: Container(
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0),
                                                      Colors.white.withOpacity(0.5),
                                                      Colors.white.withOpacity(0),
                                                    ],
                                                    stops: const [0.0, 0.5, 1.0],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Confetti effect
                                if (_confettiAnimation.value > 0)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: ConfettiPainter(
                                        progress: _confettiAnimation.value,
                                        colors: [
                                          Colors.red,
                                          Colors.blue,
                                          Colors.green,
                                          Colors.yellow,
                                          Colors.purple,
                                          Colors.orange,
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                          child: rewardItem,
                        );
                      }
                      
                      return rewardItem;
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showRedemptionHistory ? Icons.history : Icons.store,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _showRedemptionHistory
                ? 'No rewards redeemed yet'
                : 'No rewards available with current filters',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          if (!_showRedemptionHistory)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _priceRange = RangeValues(0, _maxRewardPrice.toDouble());
                    _showOnlyAffordable = false;
                    _initializeItemAnimations();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Filters'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPointsBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amber.shade300, Colors.amber.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.shade200,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Points Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${widget.userProfile.totalPoints}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'points',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(Reward reward, bool isAffordable, bool isRedeemed) {
    final borderColor = reward.rarity.color;
    final backgroundColor = Colors.white;
    
    return GestureDetector(
      onTap: () {
        if (isRedeemed) {
          _showRewardDetails(context, reward, true);
        } else if (widget.onRewardTap != null) {
          widget.onRewardTap!(reward);
        } else {
          _showRewardDetails(context, reward, false);
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRedeemed ? Colors.green : borderColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reward rarity badge
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: reward.rarity.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: reward.rarity.color,
                    width: 1,
                  ),
                ),
                child: Text(
                  reward.rarity.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: reward.rarity.color,
                  ),
                ),
              ),
            ),
            
            // Reward icon
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: reward.rarity.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getRewardIcon(reward.iconName),
                      size: 48,
                      color: reward.rarity.color,
                    ),
                  ),
                ),
              ),
            ),
            
            // Reward info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reward.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${reward.pointsCost}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (isRedeemed)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAffordable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isAffordable ? 'Affordable' : 'Need More',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAffordable ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardDetails(BuildContext context, Reward reward, bool isRedeemed) {
    final isAffordable = _canAffordReward(reward);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Reward header with icon
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: reward.rarity.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: reward.rarity.color,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getRewardIcon(reward.iconName),
                            size: 40,
                            color: reward.rarity.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: reward.rarity.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    reward.rarity.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: reward.rarity.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    reward.category.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reward description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reward.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reward cost
                  const Text(
                    'Cost',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${reward.pointsCost} points',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reward status
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isRedeemed ? Icons.check_circle : (isAffordable ? Icons.shopping_cart : Icons.lock),
                        color: isRedeemed ? Colors.green : (isAffordable ? Colors.blue : Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRedeemed 
                            ? 'Redeemed on ${_getRewardRedemptionDate(reward)}' 
                            : (isAffordable 
                                ? 'Available to redeem' 
                                : 'Need ${reward.pointsCost - widget.userProfile.totalPoints} more points'),
                        style: TextStyle(
                          fontSize: 16,
                          color: isRedeemed ? Colors.green : (isAffordable ? Colors.blue : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (isRedeemed)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isAffordable ? () {
                              Navigator.of(context).pop();
                              _confirmRewardRedemption(context, reward);
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Redeem'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRewardRedemption(BuildContext context, Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to redeem "${reward.title}" for ${reward.pointsCost} points?'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your balance after redemption will be ${widget.userProfile.totalPoints - reward.pointsCost} points.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onRewardRedeem != null) {
                widget.onRewardRedeem!(reward);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    RangeValues tempPriceRange = _priceRange;
    bool tempShowOnlyAffordable = _showOnlyAffordable;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Rewards'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Range',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: tempPriceRange,
                  min: 0,
                  max: _maxRewardPrice.toDouble(),
                  divisions: 10,
                  labels: RangeLabels(
                    tempPriceRange.start.round().toString(),
                    tempPriceRange.end.round().toString(),
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      tempPriceRange = values;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${tempPriceRange.start.round()} points'),
                    Text('${tempPriceRange.end.round()} points'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: tempShowOnlyAffordable,
                      onChanged: (value) {
                        setState(() {
                          tempShowOnlyAffordable = value ?? false;
                        });
                      },
                    ),
                    const Text('Show only rewards I can afford'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _priceRange = const RangeValues(0, 1000);
                    _showOnlyAffordable = false;
                  });
                  Navigator.of(context).pop();
                  _initializeItemAnimations();
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _priceRange = tempPriceRange;
                    _showOnlyAffordable = tempShowOnlyAffordable;
                  });
                  Navigator.of(context).pop();
                  _initializeItemAnimations();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to get icon based on reward name
  IconData _getRewardIcon(String iconName) {
    switch (iconName) {
      case 'screen_time': return Icons.tv;
      case 'screen_time_plus': return Icons.tv;
      case 'movie_night': return Icons.movie;
      case 'game_night': return Icons.videogame_asset;
      case 'gaming_pass': return Icons.sports_esports;
      case 'dessert': return Icons.cake;
      case 'ice_cream': return Icons.icecream;
      case 'dinner_choice': return Icons.restaurant_menu;
      case 'baking': return Icons.bakery_dining;
      case 'skip_chore': return Icons.do_not_disturb;
      case 'late_bedtime': return Icons.bedtime;
      case 'late_bedtime_plus': return Icons.bedtime_outlined;
      case 'chore_free': return Icons.weekend;
      case 'park': return Icons.park;
      case 'restaurant': return Icons.restaurant;
      case 'movie_theater': return Icons.theaters;
      case 'theme_park': return Icons.attractions;
      case 'small_toy': return Icons.toys;
      case 'medium_toy': return Icons.toys_outlined;
      case 'large_toy': return Icons.smart_toy;
      case 'money_small': return Icons.attach_money;
      case 'money_medium': return Icons.attach_money;
      case 'money_large': return Icons.attach_money;
      case 'one_on_one': return Icons.people;
      case 'sleepover': return Icons.hotel;
      case 'day_trip': return Icons.card_travel;
      default: return Icons.redeem;
    }
  }
}

/// Widget to draw confetti animation
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final math.Random random = math.Random();
  
  ConfettiPainter({
    required this.progress,
    required this.colors,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Generate confetti particles
    final particleCount = 50;
    for (int i = 0; i < particleCount; i++) {
      final color = colors[random.nextInt(colors.length)];
      paint.color = color;
      
      // Calculate position based on progress
      final startX = size.width / 2;
      final startY = size.height / 2;
      
      final angle = random.nextDouble() * 2 * math.pi;
      final velocity = random.nextDouble() * 100 + 50;
      final gravity = 5.0;
      
      final time = progress;
      
      final x = startX + velocity * time * math.cos(angle);
      final y = startY + velocity * time * math.sin(angle) + gravity * time * time;
      
      // Draw confetti piece
      final confettiSize = random.nextDouble() * 6 + 2;
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: confettiSize,
        height: confettiSize,
      );
      
      // Rotate confetti
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + time * 5);
      canvas.translate(-x, -y);
      
      // Different shapes for variety
      final shape = random.nextInt(3);
      switch (shape) {
        case 0:
          // Rectangle
          canvas.drawRect(rect, paint);
          break;
        case 1:
          // Circle
          canvas.drawCircle(Offset(x, y), confettiSize / 2, paint);
          break;
        case 2:
          // Triangle
          final path = Path();
          path.moveTo(x, y - confettiSize / 2);
          path.lineTo(x - confettiSize / 2, y + confettiSize / 2);
          path.lineTo(x + confettiSize / 2, y + confettiSize / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
      
      canvas.restore();
    }
  }
  
  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Widget to display a rewards store with a provider for the gamification service
class RewardsStoreProviderWidget extends StatelessWidget {
  final UserProfile userProfile;
  final bool showPurchaseAnimation;
  final Reward? newlyPurchasedReward;

  const RewardsStoreProviderWidget({
    Key? key,
    required this.userProfile,
    this.showPurchaseAnimation = false,
    this.newlyPurchasedReward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationServiceInterface>(
      builder: (context, gamificationService, child) {
        return FutureBuilder<List<Reward>>(
          future: gamificationService.getAllRewards(),
          builder: (context, allRewardsSnapshot) {
            if (!allRewardsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<List<Reward>>(
              future: gamificationService.getUserRedeemedRewards(userProfile.id),
              builder: (context, userRewardsSnapshot) {
                if (!userRewardsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RewardsStoreWidget(
                  userProfile: userProfile,
                  availableRewards: allRewardsSnapshot.data!,
                  redeemedRewards: userRewardsSnapshot.data!,
                  showPurchaseAnimation: showPurchaseAnimation,
                  newlyPurchasedReward: newlyPurchasedReward,
                  onRewardRedeem: (reward) async {
                    final success = await gamificationService.redeemReward(
                      userProfile.id,
                      reward.id,
                    );
                    
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully redeemed "${reward.title}"!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Failed to redeem reward. Try again later.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
