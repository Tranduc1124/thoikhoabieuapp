import 'package:flutter_test/flutter_test.dart';
import 'package:thoikhoabieuapp/models/schedule_model.dart';

void main() {
  test('formats minutes as HH:mm', () {
    expect(formatMinutes(7 * 60 + 5), '07:05');
    expect(formatMinutes(18 * 60 + 30), '18:30');
  });
}
