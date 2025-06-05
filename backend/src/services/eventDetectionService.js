
class EventDetectionService {
  async extractEvents(aiResponse) {
    console.log('Extracting events from AI response...');

    try {
      let jsonStr = aiResponse;
      // Extract the first complete JSON object if response has extra text
      const extractJson = text => {
        const start = text.indexOf('{');
        if (start === -1) return null;
        let depth = 0;
        for (let i = start; i < text.length; i++) {
          if (text[i] === '{') depth++;
          if (text[i] === '}') depth--;
          if (depth === 0) {
            return text.slice(start, i + 1);
          }
        }
        return null;
      };

      const extracted = extractJson(aiResponse);
      if (extracted) {
        jsonStr = extracted;
      }

      const parsed = JSON.parse(jsonStr);
      const rawEvents = Array.isArray(parsed.evenimente) ? parsed.evenimente : [];
      const unique = new Set();
      const events = [];

      rawEvents
        .filter(ev => ev && (ev.location || ev.time || ev.allDay))
        .forEach(ev => {
          const dateTime = this.parseDateTime(ev.date, ev.time);
          const key = `${ev.title}|${dateTime}`;
          if (!unique.has(key)) {
            unique.add(key);
            events.push({
              title: ev.title,
              dateTime,
              location: ev.location || '',
              eventType: ev.type || 'Eveniment',
              isAllDay: ev.allDay || !ev.time
            });
          }
        });

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
      const [day, month, year] = dateStr.split('/').map(num => parseInt(num));
      const date = new Date(year, month - 1, day);

      if (timeStr) {
        const numeric = /(\d{1,2})(?::(\d{2}))?/.exec(timeStr);
        if (numeric) {
          const hours = parseInt(numeric[1], 10);
          const minutes = parseInt(numeric[2] || '0', 10);
          date.setHours(hours, minutes);
        } else {
          // Unrecognised format, default to noon
          date.setHours(12, 0);
        }
      } else {
        date.setHours(12, 0);
      }

      return date.toISOString();
    } catch (error) {
      console.error('Error parsing date/time:', error);
      return new Date().toISOString();
    }
  }
}

module.exports = new EventDetectionService(); 
