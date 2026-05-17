import 'package:flutter_test/flutter_test.dart';
import 'package:thoikhoabieuapp/models/schedule_model.dart';
import 'package:thoikhoabieuapp/utils/vietnamese_calendar_utils.dart';

void main() {
  test('formats minutes as HH:mm', () {
    expect(formatMinutes(7 * 60 + 5), '07:05');
    expect(formatMinutes(18 * 60 + 30), '18:30');
  });

  test('calendar month grid is Monday based and stable', () {
    final days = VietnameseCalendarUtils.monthGridDays(DateTime(2026, 9));

    expect(days.length, 42);
    expect(days.first.weekday, DateTime.monday);
    expect(VietnameseCalendarUtils.dateKey(DateTime(2026, 9, 2)), '2026-09-02');
    expect(
      VietnameseCalendarUtils.holidayLabel(DateTime(2026, 9, 2)),
      'Quốc khánh',
    );
  });
}
