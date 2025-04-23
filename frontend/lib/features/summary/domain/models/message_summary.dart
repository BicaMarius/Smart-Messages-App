import 'package:frontend/features/home/domain/models/event_details.dart';

class MessageSummary {
  final String summary;
  final List<EventDetails> events;

  MessageSummary({
    required this.summary,
    required this.events,
  });

  factory MessageSummary.fromJson(Map<String, dynamic> json) {
    return MessageSummary(
      summary: json['summary'] as String,
      events: (json['events'] as List)
          .map((e) => EventDetails(
                title: e['title'] as String,
                dateTime: DateTime.parse(e['dateTime'] as String),
                location: e['location'] as String,
                eventType: e['eventType'] as String?,
                isAllDay: e['isAllDay'] as bool? ?? false,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'events': events.map((e) => {
            'title': e.title,
            'dateTime': e.dateTime.toIso8601String(),
            'location': e.location,
            'eventType': e.eventType,
            'isAllDay': e.isAllDay,
          }).toList(),
    };
  }
} 