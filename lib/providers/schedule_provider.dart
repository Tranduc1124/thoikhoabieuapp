import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_model.dart';
import '../models/study_log_model.dart';
import '../repositories/schedule_repository.dart';
import 'auth_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedDayProvider = StateProvider<int>((ref) => DateTime.now().weekday);
final scheduleOrderProvider = StateProvider<Map<int, List<String>>>(
  (ref) => const {},
);

final scheduleRepositoryProvider = Provider<ScheduleRepository?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return null;
  return ScheduleRepository(userId: user.uid);
});

final schedulesProvider = FutureProvider<List<ScheduleModel>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  if (repository == null) return const [];
  return repository.loadSchedules();
});

final todaySchedulesProvider = Provider<AsyncValue<List<ScheduleModel>>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final today = DateTime.now().weekday;
  return ref.watch(schedulesProvider).whenData((items) {
    final filtered = items
        .where((item) => item.dayOfWeek == today)
        .where((item) => query.isEmpty || _matchesScheduleQuery(item, query))
        .toList();
    return _orderedSchedules(filtered, ref.watch(scheduleOrderProvider)[today]);
  });
});

final selectedDaySchedulesProvider = Provider<AsyncValue<List<ScheduleModel>>>((
  ref,
) {
  final day = ref.watch(selectedDayProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return ref.watch(schedulesProvider).whenData((items) {
    final filtered = items
        .where((item) => item.dayOfWeek == day)
        .where((item) => query.isEmpty || _matchesScheduleQuery(item, query))
        .toList();
    return _orderedSchedules(filtered, ref.watch(scheduleOrderProvider)[day]);
  });
});

List<ScheduleModel> _orderedSchedules(
  List<ScheduleModel> items,
  List<String>? orderedIds,
) {
  final order = orderedIds == null
      ? const <String, int>{}
      : {
          for (var index = 0; index < orderedIds.length; index++)
            orderedIds[index]: index,
        };
  return [...items]..sort((a, b) {
    final aOrder = order[a.id];
    final bOrder = order[b.id];
    if (aOrder != null && bOrder != null) return aOrder.compareTo(bOrder);
    if (aOrder != null) return -1;
    if (bOrder != null) return 1;
    return a.startTime.compareTo(b.startTime);
  });
}

bool _matchesScheduleQuery(ScheduleModel item, String query) {
  return [
    item.subjectName,
    item.teacher,
    item.room,
    item.locationAddress,
    item.note,
    dayName(item.dayOfWeek),
  ].any((value) => value.toLowerCase().contains(query));
}

final todayStudyLogsProvider = FutureProvider<List<StudyLogModel>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  if (repository == null) return const [];
  return repository.loadStudyLogsForDate(DateTime.now());
});

final weekStudyLogsProvider = FutureProvider<List<StudyLogModel>>((ref) async {
  final repository = ref.watch(scheduleRepositoryProvider);
  if (repository == null) return const [];
  return repository.loadStudyLogsForWeek(DateTime.now());
});

final scheduleActionsProvider = Provider<ScheduleActions>(
  (ref) => ScheduleActions(ref),
);

final scheduleReorderActionsProvider = Provider<ScheduleReorderActions>(
  (ref) => ScheduleReorderActions(ref),
);

class ScheduleActions {
  const ScheduleActions(this.ref);

  final Ref ref;

  ScheduleRepository get _repository {
    final repository = ref.read(scheduleRepositoryProvider);
    if (repository == null) {
      throw StateError('Bạn cần đăng nhập trước khi tiếp tục.');
    }
    return repository;
  }

  void _refresh() {
    ref.invalidate(schedulesProvider);
    ref.invalidate(todayStudyLogsProvider);
    ref.invalidate(weekStudyLogsProvider);
  }

  Future<String> add(ScheduleModel schedule) async {
    final id = await _repository.addSchedule(schedule);
    _refresh();
    return id;
  }

  Future<int> addMany(List<ScheduleModel> schedules) async {
    final count = await _repository.addSchedules(schedules);
    _refresh();
    return count;
  }

  Future<void> update(ScheduleModel schedule) async {
    await _repository.updateSchedule(schedule);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _repository.deleteSchedule(id);
    _refresh();
  }

  Future<int> deleteByDay(int dayOfWeek) async {
    final count = await _repository.deleteSchedulesByDay(dayOfWeek);
    _refresh();
    return count;
  }

  Future<void> start(ScheduleModel schedule) async {
    await _repository.markStarted(schedule, DateTime.now());
    _refresh();
  }

  Future<void> complete(ScheduleModel schedule, String note) async {
    await _repository.markCompleted(
      schedule,
      DateTime.now(),
      noteAfterClass: note,
    );
    _refresh();
  }
}

class ScheduleReorderActions {
  const ScheduleReorderActions(this.ref);

  final Ref ref;

  void reorderDay({
    required int day,
    required int oldIndex,
    required int newIndex,
    required List<ScheduleModel> visibleItems,
  }) {
    if (oldIndex < 0 ||
        oldIndex >= visibleItems.length ||
        newIndex < 0 ||
        oldIndex == newIndex) {
      return;
    }
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final ids = visibleItems.map((item) => item.id).toList(growable: true);
    final moved = ids.removeAt(oldIndex);
    ids.insert(adjustedNewIndex.clamp(0, ids.length), moved);

    final current = ref.read(scheduleOrderProvider);
    final previousForDay = current[day] ?? const <String>[];
    final visibleSet = ids.toSet();
    final preservedHidden = previousForDay
        .where((id) => !visibleSet.contains(id))
        .toList(growable: false);
    ref.read(scheduleOrderProvider.notifier).state = {
      ...current,
      day: [...ids, ...preservedHidden],
    };
  }
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
  if ((schedules.isLoading && schedules.valueOrNull == null) ||
      (logs.isLoading && logs.valueOrNull == null)) {
    return const AsyncLoading();
  }
  if (schedules.hasError && schedules.valueOrNull == null) {
    return AsyncError(schedules.error!, schedules.stackTrace!);
  }
  if (logs.hasError && logs.valueOrNull == null) {
    return AsyncError(logs.error!, logs.stackTrace!);
  }

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
      topSubject: sorted.isEmpty ? 'Chưa có môn học' : sorted.first.key,
      completedCount: completedIds.length,
      hoursBySubject: hoursBySubject,
    ),
  );
});

final expandedCompletedCardsProvider =
    StateNotifierProvider<CompletedCardExpansionController, Map<String, bool>>(
      (ref) => CompletedCardExpansionController(),
    );

class CompletedCardExpansionController
    extends StateNotifier<Map<String, bool>> {
  CompletedCardExpansionController() : super(const {});

  void toggle(String scheduleId) {
    state = {...state, scheduleId: !(state[scheduleId] ?? false)};
  }

  void setExpanded(String scheduleId, bool value) {
    state = {...state, scheduleId: value};
  }
}
