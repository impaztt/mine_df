import '../models/enemy_type.dart';

/// M1 프로토타입 적군 (손님 + 침입자 + 보스)
const List<EnemyDef> kEnemies = [
  // === 손님 ===
  EnemyDef(
    id: 'fairy',
    name: '작은 요정',
    emoji: '🧚',
    kind: EnemyKind.customer,
    hpMul: 0.8,
    coinMul: 1.2,
    speedMul: 0.9,
  ),
  EnemyDef(
    id: 'rabbit_guest',
    name: '토끼 손님',
    emoji: '🐇',
    kind: EnemyKind.customer,
    hpMul: 0.6,
    coinMul: 1.0,
    speedMul: 1.4,
  ),
  EnemyDef(
    id: 'mermaid',
    name: '인어 손님',
    emoji: '🧜',
    kind: EnemyKind.customer,
    hpMul: 1.5,
    coinMul: 1.6,
    speedMul: 0.8,
  ),

  // === 침입자 ===
  EnemyDef(
    id: 'baby_dokkaebi',
    name: '아기 도깨비',
    emoji: '👹',
    kind: EnemyKind.intruder,
    hpMul: 1.0,
    coinMul: 0.8,
    speedMul: 1.0,
  ),
  EnemyDef(
    id: 'shadow_crow',
    name: '그림자 까마귀',
    emoji: '🐦‍⬛',
    kind: EnemyKind.intruder,
    hpMul: 1.2,
    coinMul: 1.0,
    speedMul: 1.3,
  ),
  EnemyDef(
    id: 'mountain_dokkaebi',
    name: '산도깨비',
    emoji: '👺',
    kind: EnemyKind.intruder,
    hpMul: 2.0,
    coinMul: 1.5,
    speedMul: 0.7,
  ),
];

/// 보스 정의
const List<EnemyDef> kBosses = [
  EnemyDef(
    id: 'toad_king',
    name: '두꺼비 왕',
    emoji: '🐸',
    kind: EnemyKind.boss,
    hpMul: 12,
    coinMul: 8,
    speedMul: 0.5,
  ),
  EnemyDef(
    id: 'frost_queen',
    name: '서리의 여왕',
    emoji: '❄️',
    kind: EnemyKind.boss,
    hpMul: 18,
    coinMul: 12,
    speedMul: 0.6,
  ),
  EnemyDef(
    id: 'dokkaebi_chief',
    name: '도깨비 대장',
    emoji: '👹',
    kind: EnemyKind.boss,
    hpMul: 25,
    coinMul: 20,
    speedMul: 0.55,
  ),
];

/// 현재 DAY에 등장 가능한 적 목록 (보스 제외)
List<EnemyDef> availableEnemies(int day) {
  return [
    if (day >= 1) kEnemies[0], // fairy
    if (day >= 1) kEnemies[3], // baby_dokkaebi
    if (day >= 5) kEnemies[1], // rabbit_guest
    if (day >= 8) kEnemies[4], // shadow_crow
    if (day >= 20) kEnemies[2], // mermaid
    if (day >= 30) kEnemies[5], // mountain_dokkaebi
  ];
}

EnemyDef bossForDay(int day) {
  // 10/20/30/... 보스 순환
  final idx = ((day ~/ 10) - 1) % kBosses.length;
  return kBosses[idx.clamp(0, kBosses.length - 1)];
}
