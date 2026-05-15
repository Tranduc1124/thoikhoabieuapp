class WeatherNowModel {
  const WeatherNowModel({
    required this.temperatureC,
    required this.weatherCode,
    required this.locationLabel,
    required this.updatedAt,
    this.isFromCache = false,
  });

  final double temperatureC;
  final int weatherCode;
  final String locationLabel;
  final DateTime updatedAt;
  final bool isFromCache;

  String get conditionLabel {
    return switch (weatherCode) {
      0 => 'Nắng nhẹ',
      1 || 2 => 'Ít mây',
      3 => 'Nhiều mây',
      45 || 48 => 'Sương mù',
      51 || 53 || 55 || 56 || 57 => 'Mưa phùn',
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'Mưa',
      71 || 73 || 75 || 77 || 85 || 86 => 'Lạnh',
      95 || 96 || 99 => 'Giông',
      _ => 'Thời tiết dễ chịu',
    };
  }

  bool get isRainy {
    return {
      51,
      53,
      55,
      56,
      57,
      61,
      63,
      65,
      66,
      67,
      80,
      81,
      82,
      95,
      96,
      99,
    }.contains(weatherCode);
  }

  String get summary => 'Hôm nay ${temperatureC.round()}°C · $conditionLabel';

  String supportMessage(int scheduleCount) {
    if (isRainy) {
      return 'Mưa nhẹ, nhớ đi sớm hơn nhé';
    }
    if (scheduleCount > 0) {
      return '$conditionLabel, hôm nay bạn có $scheduleCount môn học';
    }
    return '$conditionLabel, hôm nay là một ngày phù hợp để ôn tập';
  }

  Map<String, dynamic> toMap() {
    return {
      'temperatureC': temperatureC,
      'weatherCode': weatherCode,
      'locationLabel': locationLabel,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeatherNowModel.fromMap(Map<String, dynamic> data) {
    return WeatherNowModel(
      temperatureC: (data['temperatureC'] as num?)?.toDouble() ?? 0,
      weatherCode: (data['weatherCode'] as num?)?.toInt() ?? 0,
      locationLabel: (data['locationLabel'] ?? 'Việt Nam').toString(),
      updatedAt:
          DateTime.tryParse((data['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      isFromCache: data['isFromCache'] as bool? ?? false,
    );
  }
}
