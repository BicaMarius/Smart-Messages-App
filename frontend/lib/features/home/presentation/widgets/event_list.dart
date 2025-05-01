import 'package:flutter/material.dart';
import 'package:frontend/features/home/domain/models/event_details.dart';

class EventList extends StatelessWidget {
  final List<EventDetails> events;
  final Function(EventDetails) onEventTap;

  const EventList({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No events found'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () => onEventTap(event),
            leading: Icon(
              _getEventIcon(event.eventType ?? 'default'),
              color: Theme.of(context).primaryColor,
            ),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.location.isEmpty ? 'No location specified' : event.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDateTime(event.dateTime, event.isAllDay),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'meeting':
        return Icons.people;
      case 'appointment':
        return Icons.calendar_today;
      case 'birthday':
        return Icons.cake;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.event;
    }
  }

  String _formatDateTime(DateTime dateTime, bool isAllDay) {
    if (isAllDay) {
      return 'All day';
    }
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 