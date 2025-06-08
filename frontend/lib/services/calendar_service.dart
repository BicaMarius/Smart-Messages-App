import 'package:device_calendar/device_calendar.dart';
import 'package:frontend/features/home/domain/models/event_details.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/services/logger_service.dart';

class CalendarService {
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();
  
  // Map pentru a ține evidența ID-urilor evenimentelor adăugate în calendar
  final Map<String, String> _addedEventIds = {};
  
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
      LoggerService.error('Error requesting calendar permissions: $e');
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
      final calendars = calendarsResult.data ?? [];
      // Filter out calendars without valid IDs or names
      return calendars
          .where((c) => c.id != null && (c.name?.isNotEmpty ?? false))
          .toList();
    } catch (e) {
      LoggerService.error('Error retrieving calendars: $e');
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
  Future<String?> addEvent(EventDetails eventDetails, String calendarId) async {
    // For web, show a mock success message
    if (kIsWeb) {
      return 'mock-event-id'; // Mock ID for web demo
    }
    
    // First ensure we have permissions
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      return null;
    }
    
    try {
      // Convert DateTime to TZDateTime
      final startTime = _toTZDateTime(eventDetails.dateTime);
      
      // Use the isAllDay flag from EventDetails to determine if it's an all-day event
      final bool isAllDay = eventDetails.isAllDay;
      
      // For all-day events, set the end time to the next day at midnight
      // For regular events, set the end time to 1 hour after the start time
      final endTime = isAllDay 
          ? _toTZDateTime(DateTime(eventDetails.dateTime.year, eventDetails.dateTime.month, eventDetails.dateTime.day + 1))
          : _toTZDateTime(eventDetails.dateTime.add(const Duration(hours: 1)));
      
      // Generate a unique key for this event
      final eventKey = '${eventDetails.title}_${eventDetails.dateTime.toIso8601String()}';
      
      // Create a new event
      final event = Event(
        calendarId,
        title: eventDetails.title,
        description: 'Event detected from Smart Messages App',
        start: startTime,
        end: endTime,
        location: eventDetails.location,
        allDay: isAllDay, // Use the isAllDay flag directly
      );
      
      // Add the event to the calendar
      final createEventResult = await _calendarPlugin.createOrUpdateEvent(event);
      
      if (createEventResult != null && createEventResult.isSuccess && createEventResult.data != null) {
        // Store the created event ID
        final eventId = createEventResult.data!;
        _addedEventIds[eventKey] = eventId;
        LoggerService.info('Eveniment adăugat în calendar cu ID: $eventId');
        return eventId;
      }
      
      return null;
    } catch (e) {
      LoggerService.error('Error creating calendar event: $e');
      return null;
    }
  }
  
  /// Remove an event from the calendar
  Future<bool> removeEvent(EventDetails eventDetails, String? eventId) async {
    // Skip for web
    if (kIsWeb) {
      return true; // Mock success for web
    }
    
    // First ensure we have permissions
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      return false;
    }
    
    try {
      // Generate the event key
      final eventKey = '${eventDetails.title}_${eventDetails.dateTime.toIso8601String()}';
      
      // Get the event ID from our map if not provided
      final String? idToDelete = eventId ?? _addedEventIds[eventKey];
      
      if (idToDelete == null) {
        LoggerService.error('Nu s-a găsit ID-ul evenimentului pentru ștergere');
        return false;
      }
      
      // Get all calendars
      final calendars = await getCalendars();
      
      // Try to delete from each calendar (we don't always know which one it's in)
      for (final calendar in calendars) {
        if (calendar.id != null) {
          final deleteResult = await _calendarPlugin.deleteEvent(calendar.id!, idToDelete);
          
          if (deleteResult.isSuccess && deleteResult.data != null && deleteResult.data!) {
            LoggerService.info('Eveniment șters cu succes din calendar: $idToDelete');
            // Remove the ID from our map
            _addedEventIds.remove(eventKey);
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      LoggerService.error('Error removing calendar event: $e');
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
      if (!context.mounted) return false;
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
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar permissions are required to add an event'),
        ),
      );
      return false;
    }
    
    final calendars = await getCalendars();
    if (calendars.isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No calendars found on your device'),
        ),
      );
      return false;
    }
    
    // If there's only one calendar, use that
    if (calendars.length == 1) {
      final eventId = await addEvent(eventDetails, calendars.first.id!);
      return eventId != null;
    }
    
    // Show a dialog to select a calendar
    if (!context.mounted) return false;
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
      final eventId = await addEvent(eventDetails, selectedCalendar.id!);
      return eventId != null;
    }
    
    return false;
  }
  
  /// Remove event from calendar with confirmation
  Future<bool> removeEventWithConfirmation(
    BuildContext context,
    EventDetails eventDetails
  ) async {
    // For web, show a dialog explaining that calendar integration isn't available
    if (kIsWeb) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event would be removed from calendar on a mobile device'),
          duration: Duration(seconds: 2),
        ),
      );
      return true; // Return true for demo purposes
    }
    
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendar permissions are required to remove an event'),
        ),
      );
      return false;
    }
    
    // Ask for confirmation
    if (!context.mounted) return false;
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Calendar'),
        content: Text('Are you sure you want to remove "${eventDetails.title}" from your calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (shouldRemove == true) {
      final success = await removeEvent(eventDetails, null);
      
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Event removed from calendar' 
              : 'Failed to remove event from calendar',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      
      return success;
    }
    
    return false;
  }
} 