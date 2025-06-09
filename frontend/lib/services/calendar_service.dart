import 'package:device_calendar/device_calendar.dart';
import 'package:frontend/features/home/domain/models/event_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:frontend/services/logger_service.dart';

class CalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  final Map<String, String> _addedIds = {};          // eventKey → eventId

  CalendarService() { tz_data.initializeTimeZones(); }

  /* ───────── PERMISSIONS (public wrapper) ───────── */
  Future<bool> requestPermissions() => _requestPermissions();

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;

    try {
      var res = await _plugin.hasPermissions();
      if (res.isSuccess && res.data == true) return true;

      res = await _plugin.requestPermissions();
      return res.isSuccess && res.data == true;
    } catch (e) {
      LoggerService.error('Calendar perm error: $e');
      return false;
    }
  }

  /* ───────── LIST CALENDARS ───────── */
  Future<List<Calendar>> _retrieveCalendars() async {
    if (!await _requestPermissions()) return <Calendar>[];

    try {
      final res = await _plugin.retrieveCalendars();

      final data = (res.isSuccess && res.data != null)
          ? res.data!
          : <Calendar>[];

      return data.where((c) => c.id != null).toList();
    } catch (e) {
      LoggerService.error('Retrieve calendars error: $e');
      return <Calendar>[];
    }
  }

  /* ───────── TZ helper ───────── */
  tz.TZDateTime _tz(DateTime d) =>
      tz.TZDateTime(tz.local, d.year, d.month, d.day, d.hour, d.minute);

  /* ───────── ADD EVENT ───────── */
  Future<String?> addEvent(EventDetails info, String calendarId) async {
    if (kIsWeb) return 'mock-id';
    if (!await _requestPermissions()) return null;

    final start = _tz(info.dateTime);
    final end   = info.isAllDay
        ? _tz(DateTime(info.dateTime.year, info.dateTime.month, info.dateTime.day + 1))
        : _tz(info.dateTime.add(const Duration(hours: 1)));

    final event = Event(
      calendarId,
      title: info.title,
      description: 'Event detected from Smart Messages App',
      start: start,
      end: end,
      location: info.location,
      allDay: info.isAllDay,
    );

    final res = await _plugin.createOrUpdateEvent(event);
    if (res != null && res.isSuccess && res.data != null) {
      final key = '${info.title}_${info.dateTime.toIso8601String()}';
      _addedIds[key] = res.data!;
      return res.data!;
    }
    return null;
  }

  /* ───────── REMOVE EVENT ───────── */
  Future<bool> removeEvent(EventDetails info, String? eventId) async {
    if (kIsWeb) return true;
    if (!await _requestPermissions()) return false;

    final key = '${info.title}_${info.dateTime.toIso8601String()}';
    final id  = eventId ?? _addedIds[key];
    if (id == null) return false;

    final cals = await _retrieveCalendars();
    for (final cal in cals) {
      final res = await _plugin.deleteEvent(cal.id!, id);
      if (res.isSuccess && res.data == true) {
        _addedIds.remove(key);
        return true;
      }
    }
    return false;
  }

  /* ───────── UI: ADD WITH SELECTION ───────── */
  Future<bool> addEventWithCalendarSelection(
      BuildContext ctx, EventDetails info) async {

    if (kIsWeb) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Calendar integration is mobile-only')));
      }
      return true;
    }

    if (!await _requestPermissions()) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Calendar permission required')));
      }
      return false;
    }

    final cals = await _retrieveCalendars();
    if (cals.isEmpty) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('No calendars found')));
      }
      return false;
    }

    if (cals.length == 1) {
      return (await addEvent(info, cals.first.id!)) != null;
    }

    if (!ctx.mounted) return false;
    final sel = await showDialog<Calendar>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Select Calendar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: cals.length,
            itemBuilder: (_, i) {
              final cal = cals[i];

              final title = cal.name ??
                            cal.accountName ??
                            cal.accountType ??
                            cal.id ??
                            'Unknown Calendar';

              final subtitle = cal.accountName;

              final showSubtitle =
                  subtitle != null &&
                  subtitle.isNotEmpty &&
                  subtitle.toLowerCase() != title.toLowerCase();

              return ListTile(
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: showSubtitle
                    ? Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () => Navigator.of(ctx).pop(cal),
              );
            },
          ),
        ),
      ),
    );

    if (sel != null && sel.id != null) {
      return (await addEvent(info, sel.id!)) != null;
    }
    return false;
  }

  /* ───────── UI: REMOVE WITH CONFIRM ───────── */
  Future<bool> removeEventWithConfirmation(
      BuildContext ctx, EventDetails info) async {

    if (kIsWeb) return true;
    if (!await _requestPermissions()) return false;

    if (!ctx.mounted) return false;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Remove from Calendar'),
        content: Text('Remove “${info.title}” from calendar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );

    if (ok == true) return removeEvent(info, null);
    return false;
  }
}
