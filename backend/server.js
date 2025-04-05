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
            content: "You are a helpful assistant that summarizes WhatsApp chat messages. Provide a concise summary in Romanian."
          },
          {
            role: "user",
            content: messages.join('\n')
          }
        ],
        temperature: 0.7,
        max_tokens: 500
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
    const summary = response.data.choices[0].message.content;
    console.log('Generated summary:', summary);

    res.json({ summary });
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
