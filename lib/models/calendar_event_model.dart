import '../utils/safe_json.dart';

class CalendarEventModel {
  const CalendarEventModel({
    required this.dateKey,
    required this.title,
    required this.note,
    required this.colorValue,
    required this.pinned,
    required this.updatedAt,
  });

  final String dateKey;
  final String title;
  final String note;
  final int colorValue;
  final bool pinned;
  final DateTime updatedAt;

  bool get hasContent => title.trim().isNotEmpty || note.trim().isNotEmpty;

  CalendarEventModel copyWith({
    String? dateKey,
    String? title,
    String? note,
    int? colorValue,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return CalendarEventModel(
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      note: note ?? this.note,
      colorValue: colorValue ?? this.colorValue,
      pinned: pinned ?? this.pinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CalendarEventModel.fromMap(Map<String, dynamic> data) {
    final safe = JsonSafe.map(data);
    return CalendarEventModel(
      dateKey: JsonSafe.string(safe['dateKey']),
      title: JsonSafe.string(safe['title']),
      note: JsonSafe.string(safe['note']),
      colorValue: JsonSafe.integer(safe['colorValue'], fallback: 0xFF6A8DFF),
      pinned: JsonSafe.boolean(safe['pinned']),
      updatedAt:
          DateTime.tryParse(JsonSafe.string(safe['updatedAt'])) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'title': title,
      'note': note,
      'colorValue': colorValue,
      'pinned': pinned,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
