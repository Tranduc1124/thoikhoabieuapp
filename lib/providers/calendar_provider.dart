import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event_model.dart';
import '../services/calendar_event_service.dart';
import '../utils/vietnamese_calendar_utils.dart';
import 'auth_provider.dart';

final selectedCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final calendarEventServiceProvider = Provider<CalendarEventService>((ref) {
  final user = ref.watch(appUserProvider).valueOrNull;
  final userId = user?.id.trim().isNotEmpty == true ? user!.id : 'local';
  return CalendarEventService(userId: userId);
});

final calendarEventsProvider = FutureProvider<Map<String, CalendarEventModel>>((
  ref,
) {
  return ref.watch(calendarEventServiceProvider).loadEvents();
});

final pinnedCalendarEventProvider = Provider<CalendarEventModel?>((ref) {
  final events = ref.watch(calendarEventsProvider).valueOrNull;
  if (events == null || events.isEmpty) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final pinned =
      events.values.where((event) {
        if (!event.pinned || !event.hasContent) return false;
        final date = VietnameseCalendarUtils.parseDateKey(event.dateKey);
        return !date.isBefore(today);
      }).toList()..sort((a, b) {
        final first = VietnameseCalendarUtils.parseDateKey(a.dateKey);
        final second = VietnameseCalendarUtils.parseDateKey(b.dateKey);
        return first.compareTo(second);
      });
  return pinned.isEmpty ? null : pinned.first;
});

final calendarActionsProvider = Provider<CalendarActions>((ref) {
  return CalendarActions(ref);
});

class CalendarActions {
  CalendarActions(this._ref);

  final Ref _ref;

  Future<void> save(CalendarEventModel event) async {
    await _ref.read(calendarEventServiceProvider).saveEvent(event);
    _ref.invalidate(calendarEventsProvider);
  }

  Future<void> delete(String dateKey) async {
    await _ref.read(calendarEventServiceProvider).deleteEvent(dateKey);
    _ref.invalidate(calendarEventsProvider);
  }
}
