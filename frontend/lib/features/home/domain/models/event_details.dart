class EventDetails {
  final String title;
  final DateTime dateTime;
  final String location;
  final String? eventType;
  final bool isAllDay;

  const EventDetails({
    required this.title,
    required this.dateTime,
    required this.location,
    this.eventType,
    this.isAllDay = false,
  });

  EventDetails copyWith({
    String? title,
    DateTime? dateTime,
    String? location,
    String? eventType,
    bool? isAllDay,
  }) {
    return EventDetails(
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      eventType: eventType ?? this.eventType,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDetails &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          dateTime == other.dateTime &&
          location == other.location &&
          eventType == other.eventType &&
          isAllDay == other.isAllDay;

  @override
  int get hashCode =>
      title.hashCode ^
      dateTime.hashCode ^
      location.hashCode ^
      eventType.hashCode ^
      isAllDay.hashCode;
} 