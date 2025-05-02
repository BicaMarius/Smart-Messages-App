const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');

// Test route
router.get('/test', (req, res) => {
  console.log('Test route hit');
  res.json({ status: 'ok', message: 'Server is running' });
});

// Summarize route
router.post('/summarize', chatController.summarize);

// Ask question route
router.post('/ask', chatController.askQuestion);

module.exports = router; 