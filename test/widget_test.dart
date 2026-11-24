import 'package:flutter_test/flutter_test.dart';

import 'package:moe_moment/core/date/date_service.dart';

void main() {
  test('placeholder smoke test', () {
    const service = DateService();
    expect(service.today(), isNotNull);
  });
}
