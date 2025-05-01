const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const openRouterService = require('./services/openRouterService');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Debug messages
console.log('\n🚀 Starting server...');
console.log('\n📋 Environment variables:');
console.log(`   - 🔌 PORT: ${port}`);
console.log(`   - 🔑 OpenRouter API Key available: ${!!process.env.OPENROUTER_API_KEY}`);
console.log(`   - 📏 OpenRouter API Key length: ${process.env.OPENROUTER_API_KEY?.length || 0}`);
console.log('\n🌐 Server will listen on all network interfaces');
console.log('✅ Server started successfully');
console.log(`📡 Listening on port ${port}`);
console.log(`🔗 Server URL: http://localhost:${port}`);
console.log('💻 Server is accessible from other devices on the network\n');
