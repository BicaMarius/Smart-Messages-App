class EventDetectionService {
  extractEvents(aiResponse) {
    console.log('Extracting events from AI response...');
    
    // Split the response into summary and events sections
    const summaryMatch = aiResponse.match(/sumarizare:\s*([\s\S]*?)(?=evenimente:|$)/i);
    const eventsMatch = aiResponse.match(/evenimente:\s*([\s\S]*?)$/i);
    
    if (!eventsMatch) {
      console.log('No events section found in response');
      return { summary: summaryMatch ? summaryMatch[1].trim() : '', events: [] };
    }

    const eventsText = eventsMatch[1].trim();
    
    // Check if there are no events
    if (
      eventsText.toLowerCase().includes('nu există evenimente') || 
      eventsText.toLowerCase().includes('niciun eveniment') ||
      eventsText.match(/^\s*\[\s*\]\s*$/) // empty array
    ) {
      console.log('No events detected in response');
      return { 
        summary: summaryMatch ? summaryMatch[1].trim() : '', 
        events: [] 
      };
    }

    // Extract events from the response
    const events = this.parseEventLines(eventsText);
    
    return {
      summary: summaryMatch ? summaryMatch[1].trim() : '',
      events
    };
  }

  parseEventLines(eventsText) {
    // Split by lines starting with dash/hyphen
    const eventLines = eventsText.split('\n').filter(line => 
      line.trim().startsWith('-') && 
      line.trim().length > 1
    );
    
    const detectedEvents = [];

    for (const line of eventLines) {
      try {
        // Remove leading dash and trim
        const cleanedLine = line.replace(/^-\s*/, '').trim();
        
        // Try to extract event details using various patterns
        let eventData = this.parseEventLine(cleanedLine);
          
        if (eventData) {
          detectedEvents.push(eventData);
          console.log(`Event detected: ${eventData.title} on ${eventData.dateTime}`);
        }
      } catch (error) {
        console.error('Error parsing event line:', error);
      }
    }
    
    return detectedEvents;
  }

  parseEventLine(eventLine) {
    console.log('Parsing event line:', eventLine);
    
    // First check if this is a birthday - special handling for birthdays
    const birthdayMatch = eventLine.match(/ziua\s+(?:lui|ei)\s+([^:]+):\s*(\d{1,2}\/\d{1,2}\/\d{4})/i);
    if (birthdayMatch) {
      const personName = birthdayMatch[1].trim();
      const dateStr = birthdayMatch[2];
      
      console.log(`Detected birthday for ${personName} on ${dateStr}`);
      
      try {
        // For birthdays, set time to noon (12:00) to avoid timezone issues
        // and mark as all-day event
        const dateParts = dateStr.split('/');
        if (dateParts.length === 3) {
          const day = parseInt(dateParts[0]);
          const month = parseInt(dateParts[1]) - 1; // JS months are 0-indexed
          const year = parseInt(dateParts[2]);
          
          // Create date with noon time
          const eventDate = new Date(year, month, day, 12, 0);
          
          return {
            title: `Ziua lui ${personName}`,
            dateTime: eventDate.toISOString(),
            location: '', // Birthdays typically don't have a location
            eventType: 'Zi de naștere',
            isAllDay: true // Mark as all-day event
          };
        }
      } catch (error) {
        console.error('Error parsing birthday event:', error);
      }
    }
    
    // Try various formats to be flexible
    // Primary format: "Title: DD/MM/YYYY HH:MM, Location"
    const primaryMatch = eventLine.match(/([^:]+):\s*(\d{1,2}\/\d{1,2}\/\d{4})(?:\s+(\d{1,2}:\d{2}))?(?:,\s*(.+))?/);
    
    if (primaryMatch) {
      const title = primaryMatch[1].trim();
      const dateStr = primaryMatch[2];
      const timeStr = primaryMatch[3] || '';
      const location = primaryMatch[4] || '';

      console.log(`Primary match: title=${title}, date=${dateStr}, time=${timeStr}, location=${location}`);
      
      // Skip parsing if this is an ad-hoc meeting or seems unimportant
      if (this.isAdHocMeeting(title, eventLine)) {
        console.log('Skipping ad-hoc meeting:', title);
        return null;
      }
      
      const eventDate = this.parseEventDateTime(dateStr, timeStr);
      
      if (!isNaN(eventDate.getTime())) {
        const eventType = this.determineEventType(title);
        return {
          title: title,
          dateTime: eventDate.toISOString(),
          location: location,
          eventType: eventType,
          isAllDay: this.isAllDayEvent(title, timeStr)
        };
      }
    }
    
    // Alternative format for more flexibility
    const altMatch = eventLine.match(/([^,]+),\s*(\d{1,2}\/\d{1,2}\/\d{4})(?:\s+(\d{1,2}:\d{2}))?(?:,\s*(.+))?/);
    
    if (altMatch) {
      const title = altMatch[1].trim();
      const dateStr = altMatch[2];
      const timeStr = altMatch[3] || '';
      const location = altMatch[4] || '';

      console.log(`Alternative match: title=${title}, date=${dateStr}, time=${timeStr}, location=${location}`);
      
      // Skip parsing if this is an ad-hoc meeting or seems unimportant
      if (this.isAdHocMeeting(title, eventLine)) {
        console.log('Skipping ad-hoc meeting:', title);
        return null;
      }
      
      const eventDate = this.parseEventDateTime(dateStr, timeStr);
      
      if (!isNaN(eventDate.getTime())) {
        const eventType = this.determineEventType(title);
        return {
          title: title,
          dateTime: eventDate.toISOString(),
          location: location,
          eventType: eventType,
          isAllDay: this.isAllDayEvent(title, timeStr)
        };
      }
    }
    
    return null;
  }
  
  // Helper method to identify ad-hoc meetings that should be filtered out
  isAdHocMeeting(title, fullLine) {
    const lowerTitle = title.toLowerCase();
    const lowerLine = fullLine.toLowerCase();
    
    // Check for typical ad-hoc meeting indicators
    const adHocIndicators = [
      'întâlnire la',
      'întâlnire informală',
      'ne vedem la',
      'hai la',
      'sunt la',
      'suntem la',
      'la patiserie'
    ];
    
    // If any indicator is found, it's likely an ad-hoc meeting
    for (const indicator of adHocIndicators) {
      if (lowerTitle.includes(indicator) || lowerLine.includes(indicator)) {
        return true;
      }
    }
    
    // It's also likely ad-hoc if it's very short or generic
    if (lowerTitle === 'întâlnire' || lowerTitle === 'meeting') {
      return true;
    }
    
    return false;
  }

  determineEventType(title) {
    // Let the AI determine the event type naturally
    // This will be inferred from the title instead of hardcoded patterns
    const lowerTitle = title.toLowerCase();
    
    if (lowerTitle.includes('zi') && lowerTitle.includes('naștere')) {
      return 'Zi de naștere';
    } else if (lowerTitle.includes('aniversare')) {
      return 'Aniversare';
    } else if (lowerTitle.includes('întâlnire') || lowerTitle.includes('meeting')) {
      return 'Întâlnire';
    } else if (lowerTitle.includes('ședință') || lowerTitle.includes('webinar') || lowerTitle.includes('zoom')) {
      return 'Ședință';
    } else if (lowerTitle.includes('deadline') || lowerTitle.includes('termen limită')) {
      return 'Deadline';
    } else {
      return 'Eveniment';
    }
  }
  
  isAllDayEvent(title, timeStr) {
    // If no specific time is provided, or it's a birthday/anniversary, mark as all day
    const lowerTitle = title.toLowerCase();
    const isBirthdayOrAnniversary = 
      (lowerTitle.includes('zi') && lowerTitle.includes('naștere')) ||
      lowerTitle.includes('aniversare') ||
      lowerTitle.includes('ziua lui') ||
      lowerTitle.includes('ziua de naștere');
      
    return !timeStr || timeStr.trim() === '' || isBirthdayOrAnniversary;
  }

  parseEventDateTime(dateStr, timeStr) {
    try {
      console.log(`Parsing date: ${dateStr}, time: ${timeStr}`);
      // Support various date formats flexibly
      let day, month, year;
      
      // Check if dateStr contains a date placeholder like [DD/MM/YYYY]
      if (dateStr.includes('[') && dateStr.includes(']')) {
        // If it's a placeholder, use today's date as an approximation
        console.log('Date contains placeholders, using current date');
        const now = new Date();
        day = now.getDate();
        month = now.getMonth(); // Already 0-indexed
        year = now.getFullYear();
      } else {
        // Try to parse various date formats
        let dateParts;
        
        // Check if the date format is DD/MM/YYYY or DD.MM.YYYY or DD-MM-YYYY
        if (dateStr.includes('/')) {
          dateParts = dateStr.split('/');
        } else if (dateStr.includes('.')) {
          dateParts = dateStr.split('.');
        } else if (dateStr.includes('-')) {
          dateParts = dateStr.split('-');
        } else {
          dateParts = []; // Empty array to trigger error
        }
        
        if (dateParts.length >= 3) {
          day = parseInt(dateParts[0]);
          month = parseInt(dateParts[1]) - 1; // JS months are 0-indexed
          year = parseInt(dateParts[2]);
          
          // Handle 2-digit years
          if (year < 100) {
            year += year < 50 ? 2000 : 1900;
          }
          
          // Validate day and month ranges
          if (day < 1 || day > 31 || month < 0 || month > 11) {
            throw new Error(`Invalid date values: day=${day}, month=${month+1}`);
          }
          
          // Check if the year seems reasonable (within 10 years past/future)
          const currentYear = new Date().getFullYear();
          if (year < currentYear - 10 || year > currentYear + 10) {
            console.warn(`Suspicious year value: ${year}, current year is ${currentYear}`);
          }
        } else {
      throw new Error('Invalid date format');
    }
      }

      // Parse time if provided
      let hour = 0, minute = 0;
      
      // If this is a birthday or all-day event, set to noon by default for better display
      // instead of midnight which can show the wrong day in some timezones
      if (timeStr === 'toată ziua' || timeStr === 'all day') {
        hour = 12;
        minute = 0;
      } else if (timeStr && timeStr.trim() !== '') {
      const timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        hour = parseInt(timeParts[0]);
        minute = parseInt(timeParts[1]);
          
          // Validate hour and minute ranges
          if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            console.warn(`Invalid time values: hour=${hour}, minute=${minute}, defaulting to noon`);
            hour = 12;
            minute = 0;
          }
        }
      } else {
        // Default time for events with no specified time is noon
        hour = 12;
        minute = 0;
      }
      
      // Create date object and validate
      const eventDate = new Date(year, month, day, hour, minute);
      
      // Final validation
      if (isNaN(eventDate.getTime())) {
        console.error('Created invalid date object:', eventDate);
        throw new Error('Invalid date created');
      }
      
      console.log(`Parsed date: ${eventDate.toISOString()} from: date=${dateStr}, time=${timeStr}`);
      return eventDate;
    } catch (error) {
      console.error('Error parsing date/time:', error, 'dateStr:', dateStr, 'timeStr:', timeStr);
      // In case of error, return a reasonable fallback date (today at noon)
      const now = new Date();
      now.setHours(12, 0, 0, 0);
      return now;
    }
  }
}

module.exports = new EventDetectionService(); 