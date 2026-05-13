import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory StudyLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return StudyLogModel(
      id: doc.id,
      scheduleId: data['scheduleId'] as String? ?? '',
      subjectName: data['subjectName'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: StudyStatus.values.firstWhere(
        (value) => value.name == data['status'],
        orElse: () => StudyStatus.planned,
      ),
      noteAfterClass: data['noteAfterClass'] as String? ?? '',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'noteAfterClass': noteAfterClass,
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
    };
  }
}
