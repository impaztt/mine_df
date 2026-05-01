import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

/// 단순 SharedPreferences 기반 저장소.
/// 프로토타입 단계 — 정식 빌드에서는 Hive로 마이그레이션 권장.
class SaveRepository {
  static const _key = 'starlit_mine_save_v1';

  Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return GameState.initial();
    }
    try {
      return GameState.decode(raw);
    } catch (_) {
      return GameState.initial();
    }
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.encode());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
