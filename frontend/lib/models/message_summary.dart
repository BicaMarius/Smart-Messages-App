class MessageSummary {
  final String summary;
  final EventDetails? eventDetails;

  MessageSummary({
    required this.summary,
    this.eventDetails,
  });

  factory MessageSummary.fromJson(Map<String, dynamic> json) {
    return MessageSummary(
      summary: json['summary'] ?? '',
      eventDetails: json['eventDetails'] != null 
          ? EventDetails.fromJson(json['eventDetails']) 
          : null,
    );
  }
}

class EventDetails {
  final String title;
  final DateTime dateTime;
  final String location;

  EventDetails({
    required this.title,
    required this.dateTime,
    required this.location,
  });

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    return EventDetails(
      title: json['title'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      location: json['location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
    };
  }
} 