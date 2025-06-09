// lib/models/enums.dart
import 'package:flutter/material.dart';

// --- Core Enums ---
enum TaskStatus { pending, inProgress, completed, verified, available, assigned, pendingApproval }
enum TaskDifficulty { easy, medium, hard, challenging }
enum FamilyRole { parent, child, guardian, other }

// --- Enhanced Enums with properties for the UI ---

enum BadgeCategory { 
  taskMaster(displayName: 'Task Master'), 
  streaker(displayName: 'Streaker'),
  varietyKing(displayName: 'Variety King'),
  superHelper(displayName: 'Super Helper');

  const BadgeCategory({required this.displayName});
  final String displayName;
}

enum RewardCategory { 
  digital(displayName: 'Digital'), 
  physical(displayName: 'Physical'), 
  privilege(displayName: 'Privilege');
  
  const RewardCategory({required this.displayName});
  final String displayName;
}

enum BadgeRarity {
  common(color: Colors.brown, displayName: 'Common'),
  uncommon(color: Colors.blueGrey, displayName: 'Uncommon'),
  rare(color: Colors.blue, displayName: 'Rare'),
  epic(color: Colors.purpleAccent, displayName: 'Epic'),
  legendary(color: Colors.amber, displayName: 'Legendary');

  const BadgeRarity({required this.color, required this.displayName});
  final Color color;
  final String displayName;
}

enum RewardRarity {
  common(color: Colors.green, displayName: 'Common'),
  uncommon(color: Colors.cyan, displayName: 'Uncommon'),
  rare(color: Colors.deepOrange, displayName: 'Rare');

  const RewardRarity({required this.color, required this.displayName});
  final Color color;
  final String displayName;
}