const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const app = require('./app');
const config = require('./config/config');

dotenv.config();

const port = process.env.PORT || 3000;
const ip = '192.168.135.108';

// Debug messages
console.log('\n🚀 Starting server...');
console.log('\n📋 Environment variables:');
console.log(`   - 🔌 PORT: ${port}`);
console.log(`   - 📏 OpenRouter API Key length: ${process.env.OPENROUTER_API_KEY?.length || 0}`);

console.log('\n🌐 Server will listen on all network interfaces');

// Start the server
const server = app.listen(port, '0.0.0.0', () => {
  console.log('✅ Server started successfully');
  console.log(`📡 Listening on port ${port}`);
  console.log(`🔗 Server URL: http://localhost:${port}`);
  console.log(`🌐 Server accessible at: ${ip}:${port}`);
  console.log('💻 Server is accessible from other devices on the network\n');
});

// Handle server errors
server.on('error', (error) => {
  console.error('❌ Server error:', error);
});

// Handle client connections
server.on('connection', (socket) => {
  console.log(`🔌 New client connected from ${socket.remoteAddress}:${socket.remotePort}`);
});

// Handle client disconnections
server.on('close', () => {
  console.log('❌ Server closed');
});
