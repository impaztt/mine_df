import 'dart:math' as math;

/// 방치형 게임용 천문학적 숫자 포맷터.
///
/// 1,234         → 1.23K
/// 1,234,567     → 1.23M
/// 1.5e30        → 1.50aa  (alphabet 단위로 확장)
class BigNumberFormat {
  BigNumberFormat._();

  static const _shortUnits = ['', 'K', 'M', 'B', 'T'];

  /// `value`를 짧은 단위 문자열로 포맷.
  /// 1000 미만은 정수, 그 이상은 소수 둘째 자리.
  static String format(double value) {
    if (value.isNaN || value.isInfinite) return '∞';
    if (value < 0) return '-${format(-value)}';
    if (value < 1000) {
      return value < 10
          ? value.toStringAsFixed(value == value.truncate() ? 0 : 1)
          : value.toStringAsFixed(0);
    }

    final tier = (math.log(value) / math.ln10 / 3).floor();
    if (tier < _shortUnits.length) {
      final scaled = value / math.pow(10, tier * 3);
      return '${scaled.toStringAsFixed(2)}${_shortUnits[tier]}';
    }

    // 1e15 이상: aa, ab, ac, ..., zz
    final alphaIndex = tier - _shortUnits.length;
    final unit = _alphabetUnit(alphaIndex);
    final scaled = value / math.pow(10, tier * 3);
    return '${scaled.toStringAsFixed(2)}$unit';
  }

  static String _alphabetUnit(int index) {
    final first = index ~/ 26;
    final second = index % 26;
    return '${String.fromCharCode(97 + first)}${String.fromCharCode(97 + second)}';
  }

  /// 짧고 굵은 통합 포맷 (코인용)
  static String compact(double value) => format(value);
}
