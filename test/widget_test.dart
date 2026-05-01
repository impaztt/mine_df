import 'package:flutter_test/flutter_test.dart';

import 'package:starlit_mine/core/utils/big_number.dart';

void main() {
  test('BigNumberFormat handles small and large numbers', () {
    expect(BigNumberFormat.format(0), '0');
    expect(BigNumberFormat.format(999), '999');
    expect(BigNumberFormat.format(1234), '1.23K');
    expect(BigNumberFormat.format(1234567), '1.23M');
    expect(BigNumberFormat.format(1234567890), '1.23B');
    final huge = BigNumberFormat.format(1e18);
    expect(huge.endsWith('aa') || huge.endsWith('B'), true);
  });
}
