class EventDetectionService {
  async extractEvents(aiResponse) {
    console.log('Extracting events from AI response...');
    
    try {
      // The AI response should already be in the correct format
      // We just need to parse it into a structured format
      const events = [];
      
      // Split the response into summary and events sections
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
      
      // Check if there are no events
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

      // The AI will return events in a consistent format
      // Each line starting with - will be an event
      const eventLines = eventsText.split('\n')
        .filter(line => line.trim().startsWith('-'))
        .map(line => line.replace(/^-\s*/, '').trim());

      for (const line of eventLines) {
        try {
          // The AI will format each event line as: "Title: Date Time, Location"
          const [titlePart, detailsPart] = line.split(':').map(part => part.trim());
          if (!titlePart || !detailsPart) continue;

          const [dateTimePart, location] = detailsPart.split(',').map(part => part.trim());
          const [datePart, timePart] = dateTimePart.split(' ').filter(Boolean);

          // Create event object
          const event = {
            title: titlePart,
            dateTime: this.parseDateTime(datePart, timePart),
            location: location || '',
            eventType: 'Eveniment', // The AI will determine the type
            isAllDay: !timePart // If no time specified, it's an all-day event
          };

          events.push(event);
          console.log(`Event detected: ${event.title} on ${event.dateTime}`);
        } catch (error) {
          console.error('Error parsing event line:', error);
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