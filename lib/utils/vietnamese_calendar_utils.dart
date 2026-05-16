import 'dart:math' as math;

class LunarDateInfo {
  const LunarDateInfo({
    required this.day,
    required this.month,
    required this.year,
    required this.isLeapMonth,
  });

  final int day;
  final int month;
  final int year;
  final bool isLeapMonth;

  String get shortLabel => '$day/$month${isLeapMonth ? "n" : ""}';
}

class VietnameseCalendarUtils {
  const VietnameseCalendarUtils._();

  static const double _timeZone = 7;

  static const Map<String, String> solarHolidays = {
    '01-01': 'Tết Dương lịch',
    '02-03': 'Thành lập Đảng',
    '04-30': 'Giải phóng miền Nam',
    '05-01': 'Quốc tế Lao động',
    '09-02': 'Quốc khánh',
    '10-10': 'Giải phóng Thủ đô',
    '11-20': 'Nhà giáo Việt Nam',
    '12-22': 'Quân đội Nhân dân',
  };

  static const Map<String, String> lunarHolidays = {
    '01-01': 'Tết Nguyên đán',
    '01-15': 'Rằm tháng Giêng',
    '03-10': 'Giỗ Tổ Hùng Vương',
    '04-15': 'Phật đản',
    '05-05': 'Tết Đoan ngọ',
    '07-15': 'Vu lan',
    '08-15': 'Trung thu',
    '12-23': 'Ông Công Ông Táo',
  };

  static String dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  static DateTime parseDateKey(String key) {
    return DateTime.tryParse(key) ?? DateTime.now();
  }

  static List<DateTime> monthGridDays(DateTime month) {
    final first = DateTime(month.year, month.month);
    final gridStart = first.subtract(Duration(days: first.weekday - 1));
    return List<DateTime>.generate(42, (index) {
      return DateTime(gridStart.year, gridStart.month, gridStart.day + index);
    });
  }

  static String? holidayLabel(DateTime date) {
    final solarKey =
        '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final solar = solarHolidays[solarKey];
    if (solar != null) return solar;

    final lunar = lunarDate(date);
    final lunarKey =
        '${lunar.month.toString().padLeft(2, '0')}-${lunar.day.toString().padLeft(2, '0')}';
    return lunarHolidays[lunarKey];
  }

  static LunarDateInfo lunarDate(DateTime date) {
    final dayNumber = _jdFromDate(date.day, date.month, date.year);
    final k = ((dayNumber - 2415021.076998695) / 29.530588853).floor();
    var monthStart = _getNewMoonDay(k + 1, _timeZone);
    if (monthStart > dayNumber) {
      monthStart = _getNewMoonDay(k, _timeZone);
    }

    var a11 = _getLunarMonth11(date.year, _timeZone);
    var b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = date.year;
      a11 = _getLunarMonth11(date.year - 1, _timeZone);
    } else {
      lunarYear = date.year + 1;
      b11 = _getLunarMonth11(date.year + 1, _timeZone);
    }

    final lunarDay = dayNumber - monthStart + 1;
    final diff = ((monthStart - a11) / 29).floor();
    var lunarLeap = false;
    var lunarMonth = diff + 11;

    if (b11 - a11 > 365) {
      final leapMonthDiff = _getLeapMonthOffset(a11, _timeZone);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = true;
        }
      }
    }

    if (lunarMonth > 12) {
      lunarMonth -= 12;
    }
    if (lunarMonth >= 11 && diff < 4) {
      lunarYear -= 1;
    }

    return LunarDateInfo(
      day: lunarDay,
      month: lunarMonth,
      year: lunarYear,
      isLeapMonth: lunarLeap,
    );
  }

  static int countdownDays(String dateKey) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = parseDateKey(dateKey);
    return DateTime(date.year, date.month, date.day).difference(today).inDays;
  }

  static int _jdFromDate(int dd, int mm, int yy) {
    final a = ((14 - mm) / 12).floor();
    final y = yy + 4800 - a;
    final m = mm + 12 * a - 3;
    var jd =
        dd +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;
    if (jd < 2299161) {
      jd = dd + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - 32083;
    }
    return jd;
  }

  static int _getNewMoonDay(int k, double timeZone) {
    final t = k / 1236.85;
    final t2 = t * t;
    final t3 = t2 * t;
    final dr = math.pi / 180;
    var jd1 =
        2415020.75933 + 29.53058868 * k + 0.0001178 * t2 - 0.000000155 * t3;
    jd1 += 0.00033 * math.sin((166.56 + 132.87 * t - 0.009173 * t2) * dr);
    final m = 359.2242 + 29.10535608 * k - 0.0000333 * t2 - 0.00000347 * t3;
    final mpr = 306.0253 + 385.81691806 * k + 0.0107306 * t2 + 0.00001236 * t3;
    final f = 21.2964 + 390.67050646 * k - 0.0016528 * t2 - 0.00000239 * t3;
    var c1 =
        (0.1734 - 0.000393 * t) * math.sin(m * dr) +
        0.0021 * math.sin(2 * dr * m) -
        0.4068 * math.sin(mpr * dr) +
        0.0161 * math.sin(2 * dr * mpr) -
        0.0004 * math.sin(3 * dr * mpr) +
        0.0104 * math.sin(2 * dr * f) -
        0.0051 * math.sin((m + mpr) * dr) -
        0.0074 * math.sin((m - mpr) * dr) +
        0.0004 * math.sin((2 * f + m) * dr) -
        0.0004 * math.sin((2 * f - m) * dr) -
        0.0006 * math.sin((2 * f + mpr) * dr) +
        0.0010 * math.sin((2 * f - mpr) * dr) +
        0.0005 * math.sin((2 * mpr + m) * dr);
    final deltaT = t < -11
        ? 0.001 +
              0.000839 * t +
              0.0002261 * t2 -
              0.00000845 * t3 -
              0.000000081 * t * t3
        : -0.000278 + 0.000265 * t + 0.000262 * t2;
    c1 -= deltaT;
    return (jd1 + c1 + 0.5 + timeZone / 24).floor();
  }

  static int _getSunLongitude(int jdn, double timeZone) {
    final t = (jdn - 2451545.5 - timeZone / 24) / 36525;
    final t2 = t * t;
    final dr = math.pi / 180;
    final m =
        357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t2 * t;
    final l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2;
    var dl =
        (1.914600 - 0.004817 * t - 0.000014 * t2) * math.sin(dr * m) +
        (0.019993 - 0.000101 * t) * math.sin(2 * dr * m) +
        0.000290 * math.sin(3 * dr * m);
    var l = l0 + dl;
    l *= dr;
    l -= math.pi * 2 * (l / (math.pi * 2)).floor();
    return (l / math.pi * 6).floor();
  }

  static int _getLunarMonth11(int yy, double timeZone) {
    final off = _jdFromDate(31, 12, yy) - 2415021;
    final k = (off / 29.530588853).floor();
    var nm = _getNewMoonDay(k, timeZone);
    final sunLong = _getSunLongitude(nm, timeZone);
    if (sunLong >= 9) {
      nm = _getNewMoonDay(k - 1, timeZone);
    }
    return nm;
  }

  static int _getLeapMonthOffset(int a11, double timeZone) {
    final k = ((a11 - 2415021.076998695) / 29.530588853 + 0.5).floor();
    var last = 0;
    var i = 1;
    var arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    do {
      last = arc;
      i++;
      arc = _getSunLongitude(_getNewMoonDay(k + i, timeZone), timeZone);
    } while (arc != last && i < 14);
    return i - 1;
  }
}
