import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/home/domain/models/event_details.dart';

class DetectedEventsUI extends StatelessWidget {
  final String platformName;
  final Color platformColor;
  final List<EventDetails> events;
  final Map<int, bool> eventAddedToCalendar;
  final Function(int, EventDetails) onToggleEventCalendar;

  const DetectedEventsUI({
    super.key,
    required this.platformName,
    required this.platformColor,
    required this.events,
    required this.eventAddedToCalendar,
    required this.onToggleEventCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Events for $platformName',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: platformColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No events detected in this conversation.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isAdded = eventAddedToCalendar[index] ?? false;

            return _buildEventItem(index, event);
          },
        ),
      ],
    );
  }

  Widget _buildEventItem(int index, EventDetails event) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');

    String formattedDateTime = dateFormat.format(event.dateTime);
    if (!event.isAllDay) {
      formattedDateTime += ' ${timeFormat.format(event.dateTime)}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          event.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: platformColor),
                const SizedBox(width: 4),
                Text(
                  formattedDateTime,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            if (event.location.isNotEmpty && !event.isAllDay) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: platformColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            eventAddedToCalendar[index] == true
                ? Icons.calendar_month
                : Icons.add_to_photos,
            color: platformColor,
          ),
          onPressed: () => onToggleEventCalendar(index, event),
        ),
      ),
    );
  }
} 