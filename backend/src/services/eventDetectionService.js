class EventDetectionService {
  async extractEvents(aiResponse) {
    console.log('Extracting events from AI response...');

    try {
      const lower = aiResponse.toLowerCase();
      const summaryIndex = lower.indexOf('sumarizare:');
      const eventsIndex = lower.indexOf('evenimente:');

      let summary = '';
      if (summaryIndex !== -1) {
        const end = eventsIndex !== -1 ? eventsIndex : aiResponse.length;
        summary = aiResponse
          .slice(summaryIndex + 'sumarizare:'.length, end)
          .trim();
      }

      if (eventsIndex === -1) {
        console.log('No events section found in response');
        return { summary, events: [] };
      }

      const eventsText = aiResponse.slice(eventsIndex + 'evenimente:'.length).trim();
      if (!eventsText.startsWith('[')) {
        console.log('Events section is not JSON');
        return { summary, events: [] };
      }

      let rawEvents;
      try {
        rawEvents = JSON.parse(eventsText);
      } catch (err) {
        console.error('Failed to parse events JSON:', err);
        return { summary, events: [] };
      }

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

      return { summary, events };
    } catch (error) {
      console.error('Error in extractEvents:', error);
      return { summary: '', events: [] };
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
