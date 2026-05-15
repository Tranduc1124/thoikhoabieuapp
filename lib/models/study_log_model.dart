enum StudyStatus { planned, started, completed }

class StudyLogModel {
  const StudyLogModel({
    required this.id,
    required this.scheduleId,
    required this.subjectName,
    required this.date,
    required this.status,
    required this.noteAfterClass,
    this.completedAt,
  });

  final String id;
  final String scheduleId;
  final String subjectName;
  final DateTime date;
  final StudyStatus status;
  final String noteAfterClass;
  final DateTime? completedAt;

  factory StudyLogModel.fromMap(Map<String, dynamic> data) {
    return StudyLogModel(
      id: (data['id'] ?? '').toString(),
      scheduleId: (data['scheduleId'] ?? data['schedule_id'] ?? '').toString(),
      subjectName: (data['subjectName'] ?? data['subject_name'] ?? '')
          .toString(),
      date: _readDate(data['date']) ?? DateTime.now(),
      status: StudyStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => StudyStatus.planned,
      ),
      noteAfterClass: (data['noteAfterClass'] ?? data['note_after_class'] ?? '')
          .toString(),
      completedAt: _readDate(data['completedAt'] ?? data['completed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scheduleId': scheduleId,
      'subjectName': subjectName,
      'date': date.toIso8601String(),
      'status': status.name,
      'noteAfterClass': noteAfterClass,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
