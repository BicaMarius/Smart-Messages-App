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
    logger.debug(`Răspuns AI brut pentru procesare: ${aiResponse}`);

    try {
      // Verificăm dacă răspunsul este complet
      if (!aiResponse || aiResponse.trim() === '') {
        logger.warning('Răspuns gol de la AI pentru detectarea evenimentelor');
        return { events: [] };
      }

      let jsonStr = aiResponse.trim();
      
      // Verificăm dacă răspunsul pare să fie incomplet
      if (jsonStr.includes('"evenimente":') && !jsonStr.includes(']')) {
        logger.warning('Răspuns incomplet detectat - pare să se fi întrerupt');
        return { events: [] };
      }

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

      logger.debug(`JSON extras pentru procesare: ${jsonStr}`);

      let parsed;
      try {
        parsed = JSON.parse(jsonStr);
        logger.debug('JSON parsat cu succes');
      } catch (err) {
        logger.warning('Eroare la parsarea JSON, încercăm repararea...');
        try {
          const repairedJson = jsonrepair(jsonStr);
          logger.debug(`JSON reparat: ${repairedJson}`);
          parsed = JSON.parse(repairedJson);
          logger.debug('JSON reparat și parsat cu succes');
        } catch (repairErr) {
          logger.error('Eroare la repararea JSON:', repairErr);
          logger.error('JSON original care a cauzat eroarea:', jsonStr);
          throw err;
        }
      }

      // Verificăm dacă avem proprietatea "evenimente"
      if (!parsed.hasOwnProperty('evenimente')) {
        logger.warning('Răspunsul nu conține proprietatea "evenimente"');
        return { events: [] };
      }

      const rawEvents = Array.isArray(parsed.evenimente) ? parsed.evenimente : [];
      logger.debug(`Număr evenimente raw detectate: ${rawEvents.length}`);

      const merged = new Map();

      rawEvents
        .filter(ev => {
          if (!ev) return false;
          const hasContent = ev.title || ev.location || ev.time || ev.allDay;
          if (!hasContent) {
            logger.debug('Eveniment filtrat - lipsește conținutul necesar');
            return false;
          }
          return true;
        })
        .forEach(ev => {
          const dateTime = this.parseDateTime(ev.date || ev.dates || '', ev.time, referenceDate);
          const mergeKey = `${dateTime}|${ev.location || ''}`;
          const existing = merged.get(mergeKey);
          if (existing) {
            if (!existing.title.toLowerCase().includes(ev.title.toLowerCase())) {
              existing.title = `${existing.title} + ${ev.title}`;
            }
            logger.debug(`Eveniment combinat: ${existing.title}`);
          } else {
            const newEvent = {
              title: ev.title || 'Eveniment',
              dateTime,
              location: ev.location || '',
              eventType: ev.type || 'Eveniment',
              isAllDay: ev.allDay || !ev.time
            };
            merged.set(mergeKey, newEvent);
            logger.debug(`Eveniment nou adăugat: ${newEvent.title}`);
          }
        });

      const events = Array.from(merged.values());

      logger.debug(`Număr evenimente finale procesate: ${events.length}`);
      events.forEach(ev =>
        logger.debug(`Event detectat: ${ev.title} la data ${ev.dateTime}`)
      );

      return { events };
    } catch (error) {
      logger.error('Eroare în extractEvents:', error);
      logger.error('Răspuns AI care a cauzat eroarea:', aiResponse);
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
        if (lower.includes('mâine') || lower.includes('maine')) {
          date.setDate(base.getDate() + 1);
        } else if (lower.includes('poimâine')) {
          date.setDate(base.getDate() + 2);
        } else {
          const days = {
            'duminica': 0,
            'luni': 1,
            'marti': 2,
            'marți': 2,
            'miercuri': 3,
            'joi': 4,
            'vineri': 5,
            'sambata': 6,
            'sâmbătă': 6
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
        } else if (phrase.includes('pranz') || phrase.includes('prânz')) {
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
      logger.error('Eroare la parsarea datei/orei:', error);
      return base.toISOString();
    }
  }
}

module.exports = new EventDetectionService();