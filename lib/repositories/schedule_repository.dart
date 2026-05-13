import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class ScheduleRepository {
  ScheduleRepository({required this.userId});

  final String userId;

  CollectionReference<Map<String, dynamic>> get _schedules =>
      FirebaseService.schedules(userId);
  CollectionReference<Map<String, dynamic>> get _logs =>
      FirebaseService.studyLogs(userId);

  Stream<List<ScheduleModel>> watchSchedules() {
    return _schedules
        .orderBy('dayOfWeek')
        .orderBy('startTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ScheduleModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<StudyLogModel>> watchStudyLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _logs
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(StudyLogModel.fromFirestore).toList(),
        );
  }

  Stream<List<StudyLogModel>> watchStudyLogsForWeek(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return _logs
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(StudyLogModel.fromFirestore).toList(),
        );
  }

  Future<String> addSchedule(ScheduleModel schedule) async {
    _validate(schedule);
    final doc = await _schedules.add(schedule.toCreateMap());
    await NotificationService.scheduleClassReminder(
      schedule.copyWith(id: doc.id),
    );
    return doc.id;
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    _validate(schedule);
    await _schedules.doc(schedule.id).update(schedule.toUpdateMap());
    await NotificationService.scheduleClassReminder(schedule);
  }

  Future<void> deleteSchedule(String id) async {
    await _schedules.doc(id).delete();
    await NotificationService.cancelSchedule(id);
  }

  Future<void> markStarted(ScheduleModel schedule, DateTime date) {
    return _upsertLog(
      schedule: schedule,
      date: date,
      status: StudyStatus.started,
    );
  }

  Future<void> markCompleted(
    ScheduleModel schedule,
    DateTime date, {
    String noteAfterClass = '',
  }) {
    return _upsertLog(
      schedule: schedule,
      date: date,
      status: StudyStatus.completed,
      noteAfterClass: noteAfterClass,
    );
  }

  Future<void> _upsertLog({
    required ScheduleModel schedule,
    required DateTime date,
    required StudyStatus status,
    String noteAfterClass = '',
  }) async {
    final id = '${schedule.id}_${date.year}_${date.month}_${date.day}';
    final normalized = DateTime(date.year, date.month, date.day);
    final log = StudyLogModel(
      id: id,
      scheduleId: schedule.id,
      subjectName: schedule.subjectName,
      date: normalized,
      status: status,
      noteAfterClass: noteAfterClass,
      completedAt: status == StudyStatus.completed ? DateTime.now() : null,
    );
    await _logs.doc(id).set(log.toMap(), SetOptions(merge: true));
  }

  void _validate(ScheduleModel schedule) {
    if (schedule.subjectName.trim().isEmpty) {
      throw ArgumentError('Ten mon hoc khong duoc de trong.');
    }
    if (schedule.endTime <= schedule.startTime) {
      throw ArgumentError('Gio ket thuc phai sau gio bat dau.');
    }
  }
}
