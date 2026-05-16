import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event_model.dart';
import '../utils/safe_json.dart';

class CalendarEventService {
  const CalendarEventService({required this.userId});

  final String userId;

  Future<Map<String, CalendarEventModel>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <String, CalendarEventModel>{};
    }

    final decoded = jsonDecode(raw);
    final safe = JsonSafe.map(decoded);
    return safe.map((key, value) {
      final event = CalendarEventModel.fromMap(JsonSafe.map(value));
      return MapEntry(key, event);
    });
  }

  Future<void> saveEvent(CalendarEventModel event) async {
    final events = await loadEvents();
    final next = Map<String, CalendarEventModel>.from(events);
    if (event.hasContent || event.pinned) {
      next[event.dateKey] = event.copyWith(updatedAt: DateTime.now());
    } else {
      next.remove(event.dateKey);
    }
    await _persist(next);
  }

  Future<void> deleteEvent(String dateKey) async {
    final events = await loadEvents();
    final next = Map<String, CalendarEventModel>.from(events)..remove(dateKey);
    await _persist(next);
  }

  Future<void> _persist(Map<String, CalendarEventModel> events) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      events.map((key, value) {
        return MapEntry(key, value.toMap());
      }),
    );
    await prefs.setString(_storageKey, encoded);
  }

  String get _storageKey => 'calendar.events.$userId';
}
