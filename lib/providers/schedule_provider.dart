import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../repositories/schedule_repository.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedDayProvider = StateProvider<int>((ref) => DateTime.now().weekday);

final scheduleRepositoryProvider = Provider<ScheduleRepository?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (!FirebaseService.isAvailable || user == null) return null;
  return ScheduleRepository(userId: user.uid);
});

final schedulesProvider = StreamProvider<List<ScheduleModel>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  if (repository == null) return Stream.value(const []);
  return repository.watchSchedules();
});

final todaySchedulesProvider = Provider<AsyncValue<List<ScheduleModel>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final today = DateTime.now().weekday;
  return ref.watch(schedulesProvider).whenData((items) {
    final filtered =
        items
            .where((item) => item.dayOfWeek == today)
            .where(
              (item) =>
                  query.isEmpty ||
                  item.subjectName.toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  });
});

final selectedDaySchedulesProvider = Provider<AsyncValue<List<ScheduleModel>>>((
  ref,
) {
  final day = ref.watch(selectedDayProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return ref.watch(schedulesProvider).whenData((items) {
    final filtered =
        items
            .where((item) => item.dayOfWeek == day)
            .where(
              (item) =>
                  query.isEmpty ||
                  item.subjectName.toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  });
});

final todayStudyLogsProvider = StreamProvider<List<StudyLogModel>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  if (repository == null) return Stream.value(const []);
  return repository.watchStudyLogsForDate(DateTime.now());
});

final weekStudyLogsProvider = StreamProvider<List<StudyLogModel>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  if (repository == null) return Stream.value(const []);
  return repository.watchStudyLogsForWeek(DateTime.now());
});

final scheduleActionsProvider = Provider<ScheduleActions>(
  (ref) => ScheduleActions(ref),
);

class ScheduleActions {
  const ScheduleActions(this.ref);

  final Ref ref;

  ScheduleRepository get _repository {
    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) {
      throw StateError('Ban can dang nhap va cau hinh Firebase truoc.');
    }
    return repository;
  }

  Future<String> add(ScheduleModel schedule) =>
      _repository.addSchedule(schedule);
  Future<void> update(ScheduleModel schedule) =>
      _repository.updateSchedule(schedule);
  Future<void> delete(String id) => _repository.deleteSchedule(id);
  Future<void> start(ScheduleModel schedule) =>
      _repository.markStarted(schedule, DateTime.now());
  Future<void> complete(ScheduleModel schedule, String note) =>
      _repository.markCompleted(schedule, DateTime.now(), noteAfterClass: note);
}

class WeeklyStats {
  const WeeklyStats({
    required this.totalHours,
    required this.topSubject,
    required this.completedCount,
    required this.hoursBySubject,
  });

  final double totalHours;
  final String topSubject;
  final int completedCount;
  final Map<String, double> hoursBySubject;
}

final weeklyStatsProvider = Provider<AsyncValue<WeeklyStats>>((ref) {
  final schedules = ref.watch(schedulesProvider);
  final logs = ref.watch(weekStudyLogsProvider);
  if (schedules.isLoading || logs.isLoading) return const AsyncLoading();
  if (schedules.hasError) {
    return AsyncError(schedules.error!, schedules.stackTrace!);
  }
  if (logs.hasError) return AsyncError(logs.error!, logs.stackTrace!);

  final items = schedules.valueOrNull ?? const <ScheduleModel>[];
  final studyLogs = logs.valueOrNull ?? const <StudyLogModel>[];
  final completedIds = studyLogs
      .where((log) => log.status == StudyStatus.completed)
      .map((log) => log.scheduleId)
      .toSet();
  final hoursBySubject = <String, double>{};
  var total = 0.0;
  for (final schedule in items) {
    final hours = schedule.duration.inMinutes / 60;
    total += hours;
    hoursBySubject.update(
      schedule.subjectName,
      (value) => value + hours,
      ifAbsent: () => hours,
    );
  }
  final sorted = hoursBySubject.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return AsyncData(
    WeeklyStats(
      totalHours: total,
      topSubject: sorted.isEmpty ? 'Chua co mon hoc' : sorted.first.key,
      completedCount: completedIds.length,
      hoursBySubject: hoursBySubject,
    ),
  );
});
