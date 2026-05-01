import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../models/facility.dart';

/// 기획서 4.1 시설 6종 (M1 프로토타입 범위)
const List<FacilityDef> kFacilities = [
  FacilityDef(
    id: 'hand_pickaxe',
    name: '손곡괭이',
    icon: Icons.handyman_outlined,
    unlockDay: 1,
    baseRate: 1.0,
    baseCost: 8,
  ),
  FacilityDef(
    id: 'wood_cart',
    name: '나무 수레',
    icon: Icons.inventory_2_outlined,
    unlockDay: 5,
    baseRate: 8.0,
    baseCost: 80,
  ),
  FacilityDef(
    id: 'small_shaft',
    name: '작은 갱도',
    icon: Icons.foundation,
    unlockDay: 15,
    baseRate: 60.0,
    baseCost: 1000,
  ),
  FacilityDef(
    id: 'pickaxe_squad',
    name: '곡괭이 부대',
    icon: Icons.groups_2_outlined,
    unlockDay: 35,
    baseRate: 480.0,
    baseCost: 12000,
  ),
  FacilityDef(
    id: 'mine_elevator',
    name: '광산 엘리베이터',
    icon: Icons.elevator_outlined,
    unlockDay: 60,
    baseRate: 3800.0,
    baseCost: 150000,
  ),
  FacilityDef(
    id: 'starlight_drill',
    name: '별빛 시추기',
    icon: Icons.auto_awesome,
    unlockDay: 100,
    baseRate: 30000.0,
    baseCost: 2200000,
  ),
];

/// 시설의 현재 채굴량 (Lv별)
double facilityRate(FacilityDef def, int level) {
  if (level <= 0) return 0;
  // Lv별 +10% 채굴량
  double rate = def.baseRate * level * (1.0 + (level - 1) * 0.10);
  // 마일스톤 보너스 (10레벨마다 x2)
  final milestones =
      level ~/ GameConstants.facilityMilestoneInterval;
  for (int i = 0; i < milestones; i++) {
    rate *= GameConstants.facilityMilestoneMultiplier;
  }
  return rate;
}

/// 다음 레벨 비용
double facilityUpgradeCost(FacilityDef def, int currentLevel) {
  final next = currentLevel + 1;
  return def.baseCost *
      _pow(GameConstants.facilityCostGrowth, next - 1);
}

double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}

FacilityDef facilityById(String id) =>
    kFacilities.firstWhere((f) => f.id == id);
