import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';

import '../../data/balance/helper_data.dart';
import '../../data/models/enemy_type.dart';
import '../../data/models/game_state.dart';
import '../providers/game_provider.dart';
import 'components/background_component.dart';
import 'components/byeori_component.dart';
import 'components/enemy_component.dart';
import 'components/helper_component.dart';
import 'components/mine_component.dart';
import 'systems/auto_fire_system.dart';
import 'systems/enemy_spawner.dart';

/// 별빛 광산 — Flame 게임 월드.
/// Riverpod의 [GameProvider]와 양방향 연결되어 상태/액션을 동기화한다.
class StarlitMineGame extends FlameGame with TapCallbacks {
  StarlitMineGame({required this.providerRef});

  /// 외부에서 주입받은 GameProvider 접근자 (UI 레이어에서 set)
  GameProvider Function() providerRef;

  late BackgroundComponent _background;
  late ByeoriComponent byeori;
  late MineComponent _mine;
  late EnemySpawner _spawner;
  late AutoFireSystem _autoFire;

  /// 살아있는 적 목록 (스폰/AutoFire에서 참조)
  final List<EnemyComponent> aliveEnemies = [];
  int get aliveEnemyCount => aliveEnemies.length;

  /// 조수 컴포넌트 — provider 변경 시 재구성
  final List<HelperComponent> _helperComponents = [];

  GameState? get gameState => providerRef().state;

  // === 전투 파라미터 (provider에서 계산해서 가져옴) ===
  double get currentDamage => providerRef().currentDamage();
  double get fireRate => providerRef().currentFireRate();

  double computeEnemyHp(EnemyDef def, {bool isBoss = false}) =>
      providerRef().currentEnemyHp(def, isBoss: isBoss);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _background =
        BackgroundComponent(layer: gameState?.layer ?? 1);
    add(_background);

    _mine = MineComponent();
    add(_mine);

    byeori = ByeoriComponent();
    add(byeori);

    _spawner = EnemySpawner();
    add(_spawner);

    _autoFire = AutoFireSystem();
    add(_autoFire);

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
    _mine.position = Vector2(s.x / 2, s.y * 0.86);
    byeori.position = Vector2(s.x / 2, s.y * 0.86 - 6);
    _layoutHelpers();
  }

  void _layoutHelpers() {
    final s = size;
    final baseY = s.y * 0.86 + 4;
    for (int i = 0; i < _helperComponents.length; i++) {
      final h = _helperComponents[i];
      // 별이 양 옆에 번갈아 배치
      final dir = i.isEven ? -1 : 1;
      final dist = 60 + (i ~/ 2) * 50;
      h.position = Vector2(s.x / 2 + dir * dist, baseY);
    }
  }

  /// provider에서 조수 변경 알림 받으면 호출
  void syncHelpers() => _rebuildHelpers();

  /// 광맥 깊이 변경 시 배경 갱신
  void syncLayer(int layer) {
    _background.layer = layer;
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
      if (idx >= 3) break; // 동시 표시 최대 3마리
    }
    _layoutHelpers();
  }

  void registerEnemy(EnemyComponent e) {
    aliveEnemies.add(e);
  }

  void onEnemyKilled(EnemyComponent e) {
    aliveEnemies.remove(e);
    providerRef().onEnemyKilled(e.def);
  }

  void onEnemyReachedMine(EnemyComponent e) {
    aliveEnemies.remove(e);
    providerRef().onEnemyReachedMine(e.def);
  }

  /// DAY 클리어 시 화면의 일반 적은 정리 (보스전 진입 등)
  void clearAllEnemies() {
    for (final e in [...aliveEnemies]) {
      e.removeFromParent();
    }
    aliveEnemies.clear();
  }

  // === 탭 이벤트 — 수동 발사 (선택적) ===

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // 탭 위치 근처 적이 있으면 강한 광물 즉시 발사
    final pos = event.canvasPosition;
    final closest = _nearestTo(pos);
    if (closest == null) return;
    // 강력한 발사체 — provider 한 번만 사용 (간단 처리)
    providerRef();
    // 시각적 곡괭이 휘두름
    byeori.swing();
    closest.takeDamage(currentDamage * 1.6);
  }

  EnemyComponent? _nearestTo(Vector2 pos) {
    EnemyComponent? best;
    double bestD = double.infinity;
    for (final e in aliveEnemies) {
      final d = (e.absolutePosition - pos).length2;
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    if (best == null) return null;
    if (math.sqrt(bestD) > 90) return null;
    return best;
  }
}
