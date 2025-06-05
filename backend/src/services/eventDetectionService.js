
class EventDetectionService {
  getReferenceDate(messages) {
    if (!messages || messages.length === 0) return new Date();
    const last = messages[messages.length - 1];
    const match = last.match(/(\d{1,2})\.(\d{1,2})\.(\d{4}),\s*(\d{1,2}):(\d{2})/);
    if (match) {
      const [, d, m, y, h, min] = match.map(Number);
      return new Date(y, m - 1, d, h, min);
    }
    return new Date();
  }

  async extractEvents(aiResponse, referenceDate = new Date()) {
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
          const dateTime = this.parseDateTime(ev.date || ev.dates || '', ev.time, referenceDate);
          const key = `${ev.title}|${dateTime}|${ev.location}`;
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

  parseDateTime(dateStr = '', timeStr = '', referenceDate = new Date()) {
    const base = new Date(referenceDate);
    try {
      let date = new Date(base);

      const numericDate = /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/.exec(dateStr.trim());
      if (numericDate) {
        const [, d, m, y] = numericDate.map(Number);
        date = new Date(y, m - 1, d);
      } else if (dateStr) {
        const lower = dateStr.toLowerCase();
        if (lower.includes('m\u00e2ine') || lower.includes('maine')) {
          date.setDate(base.getDate() + 1);
        } else if (lower.includes('poim\u00e2ine')) {
          date.setDate(base.getDate() + 2);
        } else {
          const days = {
            'duminica': 0,
            'luni': 1,
            'marti': 2,
            'mar\u021bi': 2,
            'miercuri': 3,
            'joi': 4,
            'vineri': 5,
            'sambata': 6,
            's\u00e2mb\u0103t\u0103': 6
          };
          for (const [name, idx] of Object.entries(days)) {
            if (lower.includes(name)) {
              let diff = (7 + idx - base.getDay()) % 7;
              if (diff === 0) diff = 7;
              date.setDate(base.getDate() + diff);
              break;
            }
          }
        }
      }

      const numeric = /(\d{1,2})(?::(\d{2}))?/.exec(timeStr);
      let hours, minutes;
      if (numeric) {
        hours = parseInt(numeric[1], 10);
        minutes = parseInt(numeric[2] || '0', 10);
      } else {
        const phrase = `${timeStr} ${dateStr}`.toLowerCase();
        if (phrase.includes('dimine')) {
          hours = 9; minutes = 0;
        } else if (phrase.includes('pranz') || phrase.includes('pr\u00e2nz')) {
          hours = 13; minutes = 0;
        } else if (phrase.includes('seara') || phrase.includes('diseara')) {
          hours = 20; minutes = 0;
        } else if (phrase.includes('noapte')) {
          hours = 23; minutes = 0;
        } else if (phrase.includes('dupa') && phrase.includes('amiaza')) {
          hours = 16; minutes = 0;
        }
      }
      if (hours === undefined) {
        hours = 12; minutes = 0;
      }
      date.setHours(hours, minutes);

      return date.toISOString();
    } catch (error) {
      console.error('Error parsing date/time:', error);
      return base.toISOString();
    }
  }
}

module.exports = new EventDetectionService(); 
