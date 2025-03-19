import 'package:device_calendar/device_calendar.dart';
import 'package:frontend/models/message_summary.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class CalendarService {
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();
  
  CalendarService() {
    // Initialize timezone data
    tz_data.initializeTimeZones();
  }
  
  /// Request calendar permissions from the user
  Future<bool> requestPermissions() async {
    // On web platforms, return false as direct calendar access isn't available
    if (kIsWeb) {
      return false;
    }
    
    try {
      var permissionsGranted = await _calendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _calendarPlugin.requestPermissions();
        return permissionsGranted.isSuccess && permissionsGranted.data!;
      }
      return permissionsGranted.isSuccess && permissionsGranted.data!;
    } catch (e) {
      print('Error requesting calendar permissions: $e');
      return false;
    }
  }
  
  /// Get a list of available calendars on the device
  Future<List<Calendar>> getCalendars() async {
    if (kIsWeb) {
      return [];
    }
    
    try {
      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      return calendarsResult.data ?? [];
    } catch (e) {
      print('Error retrieving calendars: $e');
      return [];
    }
  }
  
  /// Convert DateTime to TZDateTime
  tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    // Get local location
    final location = tz.local;
    // Convert to TZDateTime in the local timezone
    return tz.TZDateTime(
      location,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }
  
  /// Add an event to the specified calendar
  Future<bool> addEvent(EventDetails eventDetails, String calendarId) async {
    // For web, show a mock success message
    if (kIsWeb) {
      return true; // Mock success for demo purposes
    }
    
    // First ensure we have permissions
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      return false;
    }
    
    try {
      // Convert DateTime to TZDateTime
      final startTime = _toTZDateTime(eventDetails.dateTime);
      final endTime = _toTZDateTime(eventDetails.dateTime.add(const Duration(hours: 1)));
      
      // Create a new event
      final event = Event(
        calendarId,
        title: eventDetails.title,
        description: 'Event detected from Smart Messages App',
        start: startTime,
        end: endTime,
        location: eventDetails.location,
      );
      
      // Add the event to the calendar
      final createEventResult = await _calendarPlugin.createOrUpdateEvent(event);
      return createEventResult?.isSuccess ?? false;
    } catch (e) {
      print('Error creating calendar event: $e');
      return false;
    }
  }
  
  /// Show calendar selection dialog and add the event to the selected calendar
  Future<bool> addEventWithCalendarSelection(
    BuildContext context, 
    EventDetails eventDetails
  ) async {
    // For web, show a dialog explaining that calendar integration isn't available
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event would be added to calendar on a mobile device'),
          duration: Duration(seconds: 2),
        ),
      );
      return true; // Return true for demo purposes
    }
    
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar permissions are required to add an event'),
        ),
      );
      return false;
    }
    
    final calendars = await getCalendars();
    if (calendars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No calendars found on your device'),
        ),
      );
      return false;
    }
    
    // If there's only one calendar, use that
    if (calendars.length == 1) {
      return await addEvent(eventDetails, calendars.first.id!);
    }
    
    // Show a dialog to select a calendar
    final selectedCalendar = await showDialog<Calendar>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Calendar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: calendars.length,
            itemBuilder: (context, index) {
              final calendar = calendars[index];
              return ListTile(
                title: Text(calendar.name ?? 'Unknown Calendar'),
                onTap: () => Navigator.of(context).pop(calendar),
              );
            },
          ),
        ),
      ),
    );
    
    if (selectedCalendar != null && selectedCalendar.id != null) {
      return await addEvent(eventDetails, selectedCalendar.id!);
    }
    
    return false;
  }
} 