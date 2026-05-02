import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;

import '../../app/theme/app_colors.dart';
import '../../core/utils/big_number.dart';
import '../../data/balance/helper_data.dart';
import '../../data/balance/ore_data.dart';
import '../../data/models/game_state.dart';
import '../providers/game_provider.dart';
import 'components/background_component.dart';
import 'components/byeori_component.dart';
import 'components/helper_component.dart';
import 'components/ore_drop_effect.dart';
import 'components/vein_component.dart';

/// 별빛 광산 — Flame 게임 월드. 광맥 채굴 클리커.
class StarlitMineGame extends FlameGame with TapCallbacks {
  StarlitMineGame({required this.providerRef});

  GameProvider Function() providerRef;

  late BackgroundComponent _background;
  late ByeoriComponent byeori;
  late VeinComponent vein;

  final List<HelperComponent> _helperComponents = [];
  final math.Random _rng = math.Random();

  /// 외부에서 들어오는 마지막 채굴 정보 (콤보/크리티컬 표시)
  MineHit? _lastShownHit;

  GameState? get gameState => providerRef().state;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _background =
        BackgroundComponent(layer: gameState?.layer ?? 1);
    add(_background);

    final ore = oreByRank(gameState?.mineRank ?? 1);
    vein = VeinComponent(ore: ore);
    add(vein);

    byeori = ByeoriComponent();
    add(byeori);

    _layoutScene();
    _rebuildHelpers();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layoutScene();
  }

  void _layoutScene() {
    if (!isLoaded) return;
    final s = size;
    // 광맥은 화면 가운데
    vein.position = Vector2(s.x / 2, s.y * 0.46);
    // 별이는 광맥 왼쪽 아래
    byeori.position = Vector2(s.x / 2 - 110, s.y * 0.46 + 80);
    byeori.aimAngle = -math.pi / 6;
    _layoutHelpers();
  }

  void _layoutHelpers() {
    final s = size;
    final baseY = s.y * 0.46 + 80;
    for (int i = 0; i < _helperComponents.length; i++) {
      final h = _helperComponents[i];
      // 광맥 오른쪽으로 조수 배치
      final dx = 110 + i * 56;
      h.position = Vector2(s.x / 2 + dx, baseY);
    }
  }

  void syncHelpers() => _rebuildHelpers();

  void syncLayer(int layer) {
    _background.layer = layer;
  }

  void syncMineRank(int rank) {
    vein.setOre(oreByRank(rank));
  }

  void _rebuildHelpers() {
    for (final h in _helperComponents) {
      h.removeFromParent();
    }
    _helperComponents.clear();
    final state = gameState;
    if (state == null) return;
    int idx = 0;
    for (final h in state.helpers.values) {
      if (!h.recruited) continue;
      final def = helperById(h.id);
      final comp = HelperComponent(def: def, level: h.level);
      _helperComponents.add(comp);
      add(comp);
      idx++;
      if (idx >= 3) break;
    }
    _layoutHelpers();
  }

  /// 외부에서 채굴 액션이 일어났음을 알림 (Provider → Game 동기화)
  void notifyMineHit(MineHit hit) {
    if (identical(hit, _lastShownHit)) return;
    _lastShownHit = hit;

    byeori.swing();
    vein.onHit(isCritical: hit.isCritical);
    _spawnChips(hit.isCritical ? 6 : 3);

    // 채굴 결과 텍스트 — 자동환전 ON이면 코인, OFF면 광석 개수
    final state = providerRef().state;
    final String label;
    final Color color;
    final double fontSize = hit.isCritical ? 22.0 : 16.0;
    if (state.autoSell) {
      label = '+${BigNumberFormat.format(hit.coinGained)}';
      color = hit.isCritical ? const Color(0xFFFFD86E) : AppColors.gold;
    } else {
      label = '+${BigNumberFormat.format(hit.oreAmount.toDouble())}개';
      color = hit.isCritical
          ? const Color(0xFFFFD86E)
          : AppColors.crystalTeal;
    }
    _spawnFloating(label, color, fontSize);

    // 신규 광석 발견 시 보석 보상 알림
    if (hit.newlyDiscoveredOreId != null) {
      _spawnFloating('✨ 새 광석! 💎+3', AppColors.crystalTeal, 18);
    }
  }

  void _spawnChips(int count) {
    final origin = vein.absolutePosition.clone();
    final color = vein.ore.color;
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 +
          (_rng.nextDouble() * 2 - 1) * (math.pi / 3);
      final speed = 80 + _rng.nextDouble() * 80;
      add(OreChip(
        origin: origin,
        color: color,
        angle: angle,
        speed: speed,
      ));
    }
  }

  void _spawnFloating(String text, Color color, double size) {
    // 광맥 살짝 위 + 좌우로 미세 분산 (연속 채굴 시 가독성)
    final dx = (_rng.nextDouble() * 2 - 1) * 30;
    final origin = vein.absolutePosition + Vector2(dx, -50);
    add(FloatingText(
      origin: origin,
      text: text,
      color: color,
      fontSize: size,
    ));
  }

  // === 탭 이벤트 — 수동 곡괭이질 ===

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    providerRef().tap();
  }
}
