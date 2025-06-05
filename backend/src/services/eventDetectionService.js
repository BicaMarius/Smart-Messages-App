class EventDetectionService {
  async extractEvents(aiResponse) {
    console.log('Extracting events from AI response...');

    try {
      const events = [];

      const summaryMatch = aiResponse.match(/sumarizare:\s*([\s\S]*?)(?=evenimente:|$)/i);
      const eventsMatch = aiResponse.match(/evenimente:\s*([\s\S]*?)$/i);

      if (!eventsMatch) {
        console.log('No events section found in response');
        return {
          summary: summaryMatch ? summaryMatch[1].trim() : '',
          events: []
        };
      }

      const eventsText = eventsMatch[1].trim();

      if (
        eventsText.toLowerCase().includes('nu există evenimente') ||
        eventsText.toLowerCase().includes('niciun eveniment')
      ) {
        console.log('No events detected in response');
        return {
          summary: summaryMatch ? summaryMatch[1].trim() : '',
          events: []
        };
      }

      const eventLines = eventsText
        .split('\n')
        .map(line => line.trim())
        .filter(line => line.startsWith('-'))
        .map(line => line.replace(/^-\s*/, ''));

      for (const line of eventLines) {
        const event = this.parseEventLine(line);
        if (event) {
        try {
          // The AI will format each event line as: "Title: Date Time, Location"
          const [titlePart, detailsPart] = line.split(':').map(part => part.trim());
          if (!titlePart || !detailsPart) continue;

          const [dateTimePart, location] = detailsPart.split(',').map(part => part.trim());
          const [datePart, timePart] = dateTimePart.split(' ').filter(Boolean);

          const hasLocation = location && location.length > 0;
          const hasTimeInfo = timePart || /(diminea|sear|pranz|noapte|morning|evening|afternoon|night)/i.test(detailsPart);

          const isBirthday = /ziua|nastere|birthday/i.test(titlePart);
          if (!isBirthday && (!hasLocation || !hasTimeInfo)) {

          if (!hasLocation || !hasTimeInfo) {

            console.log('Ignored potential event due to missing location or time information:', line);
            continue;
          }

          // Create event object
          const event = {
            title: titlePart,
            dateTime: this.parseDateTime(datePart, timePart),
            location: location || '',
            eventType: 'Eveniment', // The AI will determine the type
            isAllDay: !timePart || isBirthday
          };

          events.push(event);
          console.log(`Event detected: ${event.title} on ${event.dateTime}`);
        }
      }

      return {
        summary: summaryMatch ? summaryMatch[1].trim() : '',
        events
      };
    } catch (error) {
      console.error('Error in extractEvents:', error);
      return { summary: '', events: [] };
    }
  }

  parseEventLine(line) {
    try {
      const [titlePart, detailsPart] = line.split(':').map(part => part.trim());
      if (!titlePart || !detailsPart) return null;

      const [dateTimePart, location] = detailsPart.split(',').map(part => part.trim());
      const [datePart, timePart] = dateTimePart.split(' ').filter(Boolean);

      const hasLocation = location && location.length > 0;
      const hasTimeInfo =
        timePart || /(diminea|sear|pranz|noapte|morning|evening|afternoon|night)/i.test(detailsPart);
      const isBirthday = /ziua|nastere|birthday/i.test(titlePart);
      if (!isBirthday && (!hasLocation || !hasTimeInfo)) {
        console.log('Ignored potential event due to missing location or time information:', line);
        return null;
      }

      return {
        title: titlePart,
        dateTime: this.parseDateTime(datePart, timePart),
        location: location || '',
        eventType: 'Eveniment',
        isAllDay: !timePart || isBirthday
      };
    } catch (error) {
      console.error('Error parsing event line:', error);
      return null;
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
