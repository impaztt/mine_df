/// 게임 밸런싱 상수 — 추후 서버 또는 JSON에서 로드 가능하도록 분리.
class GameConstants {
  GameConstants._();

  // === DAY 진행 ===
  /// DAY 클리어를 위해 처치해야 하는 적 수 (DAY 1 기준)
  static const int baseEnemiesPerDay = 8;

  /// DAY가 올라갈수록 적 수 증가 (DAY 100마다 +5)
  static int enemiesPerDay(int day) => baseEnemiesPerDay + (day ~/ 100) * 5;

  /// 보스 등장 주기
  static const int bossDayInterval = 10;

  /// 광맥 깊이가 한 층 내려가는 주기
  static const int depthLayerInterval = 100;

  /// 최대 깊이
  static const int maxLayer = 5;

  // === 적 체력 / 보상 공식 ===
  static const double baseEnemyHp = 8.0;
  static const double enemyHpGrowth = 1.15;

  static const double baseCoinReward = 3.0;
  static const double coinGrowth = 1.13;

  /// 보스 체력 배율
  static const double bossHpMultiplier = 12.0;

  /// 손님과 침입자 비율 (0.0~1.0). 0.4 = 40%가 손님
  static const double customerRatio = 0.4;

  // === 채굴 / 발사 ===
  /// 발사체 비행 속도 (px/sec)
  static const double projectileSpeed = 420.0;

  /// 곡괭이 기본 발사 속도 (초당 발사)
  static const double baseFireRate = 1.5;

  /// 기본 발사 데미지 (광물 채굴량의 비율)
  static const double damagePerFire = 1.0;

  /// 적 이동 속도 (px/sec)
  static const double enemySpeed = 36.0;

  // === 오프라인 보상 ===
  static const Duration offlineCap = Duration(hours: 8);

  // === 산신령 (보너스 이벤트) ===
  static const Duration spiritMinInterval = Duration(seconds: 35);
  static const Duration spiritMaxInterval = Duration(seconds: 90);
  static const double spiritRewardMultiplier = 200.0; // 200초치

  // === 시설 업그레이드 ===
  /// 시설 레벨업 비용 성장 계수
  static const double facilityCostGrowth = 1.15;

  /// 마일스톤 보너스 — 10 레벨마다
  static const int facilityMilestoneInterval = 10;
  static const double facilityMilestoneMultiplier = 2.0;

  // === 적 스폰 ===
  /// 적 스폰 간격 (초)
  static const double enemySpawnInterval = 1.6;

  /// 한 번에 화면에 나타날 수 있는 최대 적 수
  static const int maxAliveEnemies = 12;
}
