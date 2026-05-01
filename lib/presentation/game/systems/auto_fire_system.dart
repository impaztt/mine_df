import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../core/constants/game_constants.dart';
import '../../../data/balance/ore_data.dart';
import '../components/enemy_component.dart';
import '../components/projectile_component.dart';
import '../starlit_mine_game.dart';

/// 별이가 가장 가까운 적을 자동 조준해 광물을 발사하는 시스템
class AutoFireSystem extends Component
    with HasGameReference<StarlitMineGame> {
  double _cooldown = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _cooldown -= dt;

    final state = game.gameState;
    if (state == null) return;

    final fireRate = game.fireRate;
    if (fireRate <= 0) return;

    final target = _findNearestEnemy();
    if (target == null) {
      // 조준 각도 0 (정면)
      game.byeori.setAim(-math.pi / 4);
      return;
    }

    // 별이의 곡괭이 끝 위치
    final origin = game.byeori.absolutePosition - Vector2(0, 40);
    final delta = target.absolutePosition - origin;
    final angle = math.atan2(delta.y, delta.x);
    game.byeori.setAim(angle);

    if (_cooldown > 0) return;

    _fire(origin, target);
    _cooldown = 1 / fireRate;
  }

  EnemyComponent? _findNearestEnemy() {
    EnemyComponent? best;
    double bestDist = double.infinity;
    final origin = game.byeori.absolutePosition;
    for (final e in game.aliveEnemies) {
      if (e.isDead) continue;
      final d = (e.absolutePosition - origin).length2;
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  void _fire(Vector2 origin, EnemyComponent target) {
    final state = game.gameState!;
    final ore = kOres.firstWhere(
      (o) => o.id == state.equippedOreId,
      orElse: () => kOres.first,
    );
    final dmg = game.currentDamage * ore.damageMul;

    final p = ProjectileComponent(
      position: origin.clone(),
      ore: ore,
      target: target,
      damage: dmg,
      speed: GameConstants.projectileSpeed,
    );
    game.add(p);
    game.byeori.swing();
  }
}
