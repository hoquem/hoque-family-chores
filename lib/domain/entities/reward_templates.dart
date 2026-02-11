import 'reward.dart';
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';

/// Pre-built reward templates for quick setup
class RewardTemplates {
  static List<RewardTemplate> get all => [
        pizzaNight,
        extraScreenTime,
        pocketMoney,
        chooseDinner,
        movieNightPick,
        streakFreeze,
        gameNightHost,
        iceCreamTrip,
        lateBedtime,
      ];

  static final pizzaNight = RewardTemplate(
    name: 'Pizza Night',
    description: 'Family pizza night with your choice of toppings',
    starCost: 500,
    iconEmoji: '🍕',
    type: RewardType.privilege,
  );

  static final extraScreenTime = RewardTemplate(
    name: '30 Min Extra Screen Time',
    description: '30 minutes of extra phone/tablet time',
    starCost: 200,
    iconEmoji: '📱',
    type: RewardType.privilege,
  );

  static final pocketMoney = RewardTemplate(
    name: '£5 Pocket Money',
    description: '£5 spending money for you',
    starCost: 1000,
    iconEmoji: '💷',
    type: RewardType.physical,
  );

  static final chooseDinner = RewardTemplate(
    name: 'Choose Family Dinner',
    description: 'Pick what the family eats for dinner',
    starCost: 300,
    iconEmoji: '🍽️',
    type: RewardType.privilege,
  );

  static final movieNightPick = RewardTemplate(
    name: 'Movie Night Pick',
    description: 'Choose the movie for family movie night',
    starCost: 400,
    iconEmoji: '🎬',
    type: RewardType.privilege,
  );

  static final streakFreeze = RewardTemplate(
    name: 'Streak Freeze',
    description: 'Protect your streak! Auto-activates if you miss a day',
    starCost: 200,
    iconEmoji: '🧊',
    type: RewardType.digital,
    isSpecial: true,
  );

  static final gameNightHost = RewardTemplate(
    name: 'Game Night Host',
    description: 'Host and choose games for family game night',
    starCost: 350,
    iconEmoji: '🎮',
    type: RewardType.privilege,
  );

  static final iceCreamTrip = RewardTemplate(
    name: 'Ice Cream Trip',
    description: 'A trip to your favorite ice cream shop',
    starCost: 400,
    iconEmoji: '🍨',
    type: RewardType.physical,
  );

  static final lateBedtime = RewardTemplate(
    name: 'Sleep 30 Min Later',
    description: 'Stay up 30 minutes past your bedtime',
    starCost: 250,
    iconEmoji: '⏰',
    type: RewardType.privilege,
  );
}

/// Template for creating rewards
class RewardTemplate {
  final String name;
  final String description;
  final int starCost;
  final String iconEmoji;
  final RewardType type;
  final bool isSpecial;

  const RewardTemplate({
    required this.name,
    required this.description,
    required this.starCost,
    required this.iconEmoji,
    required this.type,
    this.isSpecial = false,
  });

  /// Convert template to reward entity
  Reward toReward({
    required String id,
    required FamilyId familyId,
    required String creatorId,
  }) {
    return Reward(
      id: id,
      name: name,
      description: description,
      pointsCost: Points(starCost),
      iconEmoji: iconEmoji,
      type: type,
      familyId: familyId,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      isFeatured: isSpecial,
    );
  }
}
