
class EventDetectionService {
  async extractEvents(aiResponse) {
    console.log('Extracting events from AI response...');

    try {
      const parsed = JSON.parse(aiResponse);
      const rawEvents = Array.isArray(parsed.evenimente) ? parsed.evenimente : [];

      const events = rawEvents
        .filter(ev => ev && (ev.location || ev.time || ev.allDay))
        .map(ev => ({
          title: ev.title,
          dateTime: this.parseDateTime(ev.date, ev.time),
          location: ev.location || '',
          eventType: ev.type || 'Eveniment',
          isAllDay: ev.allDay || !ev.time
        }));

      events.forEach(ev =>
        console.log(`Event detected: ${ev.title} on ${ev.dateTime}`)
      );

      return { events };
    } catch (error) {
      console.error('Error in extractEvents:', error);
      return { events: [] };
    }
  }

  parseDateTime(dateStr, timeStr) {
    try {
      // Parse date in DD/MM/YYYY format
      const [day, month, year] = dateStr.split('/').map(num => parseInt(num));
      const date = new Date(year, month - 1, day);

      // If time is provided, add it to the date
      if (timeStr) {
        const [hours, minutes] = timeStr.split(':').map(num => parseInt(num));
        date.setHours(hours, minutes);
      } else {
        // For all-day events, set to noon to avoid timezone issues
        date.setHours(12, 0);
      }

      return date.toISOString();
    } catch (error) {
      console.error('Error parsing date/time:', error);
      return new Date().toISOString(); // Fallback to current date
    }
  }
}

module.exports = new EventDetectionService(); 
