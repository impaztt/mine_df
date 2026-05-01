import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../core/constants/game_constants.dart';
import '../../../data/balance/enemy_data.dart';
import '../../../data/models/enemy_type.dart';
import '../components/enemy_component.dart';
import '../starlit_mine_game.dart';

/// 적 스폰 시스템 — DAY에 맞춰 일반 적과 보스를 스폰
class EnemySpawner extends Component
    with HasGameReference<StarlitMineGame> {
  double _cooldown = 1.0;
  final math.Random _rng = math.Random();

  @override
  void update(double dt) {
    super.update(dt);
    _cooldown -= dt;

    final state = game.gameState;
    if (state == null) return;

    if (game.aliveEnemyCount >= GameConstants.maxAliveEnemies) return;

    if (_cooldown > 0) return;

    if (state.bossPhase) {
      // 보스 1체만 스폰
      if (game.aliveEnemyCount == 0) {
        _spawnBoss();
      }
      _cooldown = 2.0;
    } else {
      _spawnNormal();
      _cooldown = GameConstants.enemySpawnInterval;
    }
  }

  void _spawnNormal() {
    final state = game.gameState;
    if (state == null) return;

    final pool = availableEnemies(state.day);
    if (pool.isEmpty) return;

    // 손님 vs 침입자 비율
    final isCustomer =
        _rng.nextDouble() < GameConstants.customerRatio;
    final filtered = pool
        .where((e) =>
            (isCustomer && e.kind == EnemyKind.customer) ||
            (!isCustomer && e.kind == EnemyKind.intruder))
        .toList();
    final def = filtered.isEmpty
        ? pool[_rng.nextInt(pool.length)]
        : filtered[_rng.nextInt(filtered.length)];

    _spawn(def, isBoss: false);
  }

  void _spawnBoss() {
    final state = game.gameState;
    if (state == null) return;
    final def = bossForDay(state.day);
    _spawn(def, isBoss: true);
  }

  void _spawn(EnemyDef def, {required bool isBoss}) {
    final fromLeft = _rng.nextBool();
    final size = game.size;
    final laneY = size.y * 0.66;
    final mineX = size.x / 2;

    final pos = Vector2(
      fromLeft ? -40 : size.x + 40,
      laneY,
    );

    final hp = game.computeEnemyHp(def, isBoss: isBoss);
    final speed = GameConstants.enemySpeed * def.speedMul;

    final enemy = EnemyComponent(
      def: def,
      maxHp: hp,
      fromLeft: fromLeft,
      targetX: mineX,
      speed: speed,
    );
    enemy.position = pos;
    game.add(enemy);
    game.registerEnemy(enemy);
  }
}
