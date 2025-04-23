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

// Routes
app.use('/api', chatRoutes);

// Error handling
app.use(errorHandler);

module.exports = app; 