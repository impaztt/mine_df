/// 게임 밸런싱 상수
class GameConstants {
  GameConstants._();

  // === 광맥 깊이 시스템 ===
  /// 한 층당 들어가는 광석 등급 수 (예: 1층 1~5, 2층 6~10 ...)
  static const int oreRanksPerLayer = 5;
  static const int maxLayer = 6;

  // === 액션 ===
  /// 화면 탭으로 곡괭이질을 추가 가속할 때의 쿨다운 (초)
  static const double tapCooldown = 0.30;

  /// 기본 크리티컬 확률 (%) — 까치 치치 영입 전 기본값
  static const double baseCritChance = 3.0;

  /// 크리티컬 데미지 배수
  static const double critMultiplier = 3.0;

  // === 산신령 (보너스 이벤트) ===
  static const Duration spiritMinInterval = Duration(seconds: 60);
  static const Duration spiritMaxInterval = Duration(seconds: 150);

  /// 산신령 보너스 — 현재 코인/초의 N배
  static const double spiritCoinSeconds = 60.0;

  // === 오프라인 보상 ===
  static const Duration offlineCap = Duration(hours: 8);
}
