import 'package:frontend/models/message_summary.dart';

class MessageProcessor {
  /// Analyzes a summary text to detect possible events
  /// Returns event details if an event is found, otherwise null
  EventDetails? detectEvent(String summaryText) {
    final summaryLower = summaryText.toLowerCase();
    
    // Check if the summary contains keywords related to events
    if (_containsEventKeywords(summaryLower)) {
      // Extract date and time information
      final dateTime = _extractDateTime(summaryText);
      if (dateTime != null) {
        // Extract location
        final location = _extractLocation(summaryText);
        // Extract event title
        final title = _extractTitle(summaryText);
        
        return EventDetails(
          title: title,
          dateTime: dateTime,
          location: location,
        );
      }
    }
    
    return null;
  }
  
  bool _containsEventKeywords(String text) {
    final eventKeywords = [
      'întâlnim', 'întâlni', 'întâlnire',
      'vedem', 'vezi', 'vedere',
      'meeting', 'meet',
      'ora', 'time', 'la', 'at',
      'cafenea', 'coffee', 'restaurant',
      'confirm', 'confirmare'
    ];
    
    return eventKeywords.any((keyword) => text.contains(keyword));
  }
  
  DateTime? _extractDateTime(String text) {
    // Simple regex to extract time patterns like "18:00", "18.00", "6pm", etc.
    final timeRegex = RegExp(r'(\d{1,2})[:.]\d{2}|(\d{1,2})\s?(am|pm)');
    final timeMatch = timeRegex.firstMatch(text);
    
    if (timeMatch != null) {
      try {
        final now = DateTime.now();
        // Default to today's date with the extracted time
        // In a real app, you'd do more sophisticated date/time extraction
        final hour = int.parse(timeMatch.group(1) ?? timeMatch.group(2) ?? '0');
        final isPM = timeMatch.group(3)?.toLowerCase() == 'pm';
        
        return DateTime(
          now.year, 
          now.month, 
          now.day, 
          isPM ? (hour < 12 ? hour + 12 : hour) : hour,
          0, // minutes
        );
      } catch (e) {
        print('Error parsing date/time: $e');
      }
    }
    
    return null;
  }
  
  String _extractLocation(String text) {
    final locationKeywords = ['la', 'at', 'in', 'cafenea', 'restaurant', 'coffee', 'loc'];
    
    for (final keyword in locationKeywords) {
      final index = text.toLowerCase().indexOf(keyword);
      if (index != -1) {
        // Try to extract a location phrase following the keyword
        // This is a simplified approach - in a real app, you would use NLP
        final remainingText = text.substring(index + keyword.length).trim();
        final words = remainingText.split(' ');
        if (words.isNotEmpty) {
          // Take up to 3 words as the location
          return words.take(3).join(' ');
        }
      }
    }
    
    return 'Unknown location';
  }
  
  String _extractTitle(String text) {
    // Extract a suitable title from the text
    // In a real app, this would be more sophisticated with NLP
    final words = text.split(' ');
    if (words.length > 5) {
      return words.take(5).join(' ') + '...';
    }
    return text;
  }
} 