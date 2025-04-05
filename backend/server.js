require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const axios = require('axios');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

console.log('Starting server...');
console.log('Environment variables:');
console.log('- PORT:', process.env.PORT);
console.log('- OpenRouter API Key available:', !!process.env.OPENROUTER_API_KEY);
console.log('- OpenRouter API Key length:', process.env.OPENROUTER_API_KEY ? process.env.OPENROUTER_API_KEY.length : 0);
console.log('Server will listen on all network interfaces');

// Middleware
app.use(cors({
  origin: '*', // Allow all origins
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Log all requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Test route
app.get('/api/test', (req, res) => {
  console.log('Test route hit');
  res.json({ status: 'ok', message: 'Server is running' });
});

// Summarize route
app.post('/api/summarize', async (req, res) => {
  try {
    const { messages } = req.body;
    console.log('Received request to summarize messages');
    console.log('Number of messages:', messages.length);
    console.log('First message:', messages[0]);
    console.log('Last message:', messages[messages.length - 1]);

    console.log('Making request to OpenRouter API...');
    const response = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model: "deepseek/deepseek-r1-distill-qwen-32b:free",
        messages: [
          {
            role: "system",
            content: "Ești un asistent care sumarizează conversații și detectează evenimente din mesajele WhatsApp. Oferă un rezumat concis în limba română, FĂRĂ a folosi titluri precum 'Rezumat:' sau 'Evenimente posibile:'. Returnează rezumatul direct, fără introduceri. Pentru evenimentele detectate, folosește un format structurat pentru a semnala: 'EVENIMENT_DETECTAT:' urmat de detaliile evenimentului. Dacă detectezi urări de tip 'La mulți ani', 'zi de naștere', etc., interpretează data mesajului ca fiind ziua de naștere a persoanei respective. Formatează evenimentele detectate astfel:\nEVENIMENT_DETECTAT: [Tip Eveniment]\nTitlu: [Titlu Eveniment]\nData: [ZZ/LL/AAAA]\nOra: [HH:MM]\nLocație: [Locație]\n\nUnde [Tip Eveniment] poate fi: Zi de naștere, Întâlnire, Ședință, Activitate, etc."
          },
          {
            role: "user",
            content: messages.join('\n')
          }
        ],
        temperature: 0.7,
        max_tokens: 800
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'HTTP-Referer': 'http://localhost:3000',
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('OpenRouter API response received');
    console.log('Response status:', response.status);
    const aiResponse = response.data.choices[0].message.content;
    console.log('Generated response:', aiResponse);

    // Process the AI response to extract events
    const eventRegex = /EVENIMENT_DETECTAT:\s*([^\n]+)\nTitlu:\s*([^\n]+)\nData:\s*([^\n]+)\nOra:\s*([^\n]*)\nLocație:\s*([^\n]*)/gis;
    let match;
    const detectedEvents = [];
    
    // Try to find structured event data in the response
    while ((match = eventRegex.exec(aiResponse)) !== null) {
      const eventType = match[1]?.trim();
      const title = match[2]?.trim();
      const dateStr = match[3]?.trim();
      const timeStr = match[4]?.trim();
      const location = match[5]?.trim() || '';
      
      if (title && dateStr) {
        try {
          // Parse date in DD/MM/YYYY format
          const dateParts = dateStr.split(/[\/\-\.]/);
          if (dateParts.length >= 3) {
            const day = parseInt(dateParts[0]);
            const month = parseInt(dateParts[1]) - 1; // JS months are 0-indexed
            const year = parseInt(dateParts[2]);
            
            // Parse time
            let hour = 12, minute = 0;
            if (timeStr && timeStr.trim() !== '') {
              const timeParts = timeStr.split(':');
              if (timeParts.length >= 2) {
                hour = parseInt(timeParts[0]);
                minute = parseInt(timeParts[1]);
              }
            }
            
            const eventDate = new Date(year, month, day, hour, minute);
            
            // Add event if date parsing succeeded
            if (!isNaN(eventDate.getTime())) {
              detectedEvents.push({
                title: title,
                dateTime: eventDate.toISOString(),
                location: location,
                eventType: eventType
              });
            }
          }
        } catch (error) {
          console.error('Error parsing event date:', error);
        }
      }
    }

    // If no events are detected using the structured format,
    // try to extract birthday events from messages with "La mulți ani"
    if (detectedEvents.length === 0) {
      const birthdayRegex = /(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4}),\s+\d{1,2}:\d{2}\s+\-\s+([^:]+):\s+La\s+mulți\s+ani/i;
      
      for (const message of messages) {
        const match = birthdayRegex.exec(message);
        if (match) {
          const day = parseInt(match[1]);
          const month = parseInt(match[2]) - 1; // JS months are 0-indexed
          const year = parseInt(match[3]);
          const person = match[4].trim().replace('You', 'Persoana din conversație');
          
          const recipientPerson = messages
            .filter(msg => !msg.includes(person) && msg.includes(':'))
            .map(msg => {
              const parts = msg.split(':');
              return parts.length > 0 ? parts[0].split('-').pop().trim() : '';
            })
            .find(name => name && name !== 'You');
          
          if (recipientPerson) {
            // Creăm data fără oră specifică (setăm ora 00:00 pentru standardizare)
            const eventDate = new Date(year, month, day, 0, 0, 0);
            
            // Verificăm că data este validă
            if (!isNaN(eventDate.getTime())) {
              detectedEvents.push({
                title: `Ziua de naștere a lui ${recipientPerson}`,
                dateTime: eventDate.toISOString(),
                location: '',
                eventType: 'Zi de naștere'
              });

              // Log pentru debug
              console.log(`Eveniment de zi de naștere detectat pentru ${recipientPerson} la data ${eventDate.toISOString()}`);
            }
          }
        }
      }
    }

    // Debug: afișăm evenimentele detectate pentru verificare
    if (detectedEvents.length > 0) {
      console.log(`Au fost detectate ${detectedEvents.length} evenimente:`);
      detectedEvents.forEach((event, index) => {
        console.log(`${index + 1}. ${event.title}, data: ${event.dateTime}`);
      });
    } else {
      console.log('Nu au fost detectate evenimente');
    }

    // Remove event sections from summary 
    let summary = aiResponse.replace(/EVENIMENT_DETECTAT:[^]+(Locație:[^\n]*\n?)/g, '').trim();

    res.json({ 
      summary,
      detectedEvents
    });
  } catch (error) {
    console.error('Error in /api/summarize:');
    if (error.response) {
      console.error('Response error data:', error.response.data);
      console.error('Response error status:', error.response.status);
      console.error('Response error headers:', error.response.headers);
    } else if (error.request) {
      console.error('Request error:', error.request);
    } else {
      console.error('Error message:', error.message);
    }
    res.status(500).json({ error: error.message });
  }
});

// Listen on all network interfaces
app.listen(port, '0.0.0.0', () => {
    console.log(`Server started successfully`);
    console.log(`Listening on port ${port}`);
    console.log(`Server URL: http://localhost:${port}`);
    console.log(`Server is accessible from other devices on the network`);
});
