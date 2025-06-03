const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const config = require('./config/config');
const errorHandler = require('./middlewares/errorHandler');
const logger = require('./middlewares/logger');
const chatRoutes = require('./routes/chatRoutes');

const app = express();

// Middleware
app.use(cors(config.cors));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, '../public')));
app.use(logger);

// Health check endpoint
app.get('/healthz', (req, res) => {
    res.status(200).json({ 
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Routes
app.use('/api', chatRoutes);

// Error handling
app.use(errorHandler);

module.exports = app; 