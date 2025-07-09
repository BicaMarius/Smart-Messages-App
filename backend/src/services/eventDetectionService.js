const { jsonrepair } = require('jsonrepair');
const logger = require('./loggerService');

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
    logger.debug('Extracting events from AI response...');

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

      let extracted = extractJson(aiResponse);
      if (!extracted) {
        const startIdx = aiResponse.indexOf('{');
        const endIdx = aiResponse.lastIndexOf('}');
        if (startIdx !== -1 && endIdx !== -1 && endIdx > startIdx) {
          extracted = aiResponse.slice(startIdx, endIdx + 1);
        }
      }
      if (extracted) {
        jsonStr = extracted;
      }

      let parsed;
      try {
        parsed = JSON.parse(jsonStr);
      } catch (err) {
        try {
          parsed = JSON.parse(jsonrepair(jsonStr));
        } catch (repairErr) {
          logger.error(`Error repairing JSON: ${repairErr.message}`);
          throw err;
        }
      }
      const rawEvents = Array.isArray(parsed.evenimente) ? parsed.evenimente : [];
      const merged = new Map();

      rawEvents
        .filter(ev => ev && (ev.location || ev.time || ev.allDay))
        .forEach(ev => {
          const dateTime = this.parseDateTime(ev.date || ev.dates || '', ev.time, referenceDate);
          const mergeKey = `${dateTime}|${ev.location || ''}`;
          const existing = merged.get(mergeKey);
          if (existing) {
            if (!existing.title.toLowerCase().includes(ev.title.toLowerCase())) {
              existing.title = `${existing.title} + ${ev.title}`;
            }
          } else {
            merged.set(mergeKey, {
              title: ev.title,
              dateTime,
              location: ev.location || '',
              eventType: ev.type || 'Eveniment',
              isAllDay: ev.allDay || !ev.time
            });
          }
        });

      const events = Array.from(merged.values());

      events.forEach(ev => {
        logger.event(`Event detected: ${ev.title} on ${ev.dateTime}`);
      });

      return { events };
    } catch (error) {
      logger.error(`Error in extractEvents: ${error.message}`);
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

      let hours, minutes;
      const numeric = /(\d{1,2})(?::(\d{2}))?/.exec(timeStr);
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
        } else {
          hours = 12; minutes = 0;
        }
      }

      if (hours === undefined) {
        hours = 12; minutes = 0;
      }

      date.setHours(hours, minutes);
      return date.toISOString();
    } catch (error) {
      logger.error(`Error parsing date/time: ${error.message}`);
      return base.toISOString();
    }
  }
}
module.exports = new EventDetectionService(); 