const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const config = require('./config/config');
const errorHandler = require('./middlewares/errorHandler');
const logger = require('./middlewares/logger');
const chatRoutes = require('./routes/chatRoutes');
const os = require('os');

const app = express();

// Middleware
app.use(cors(config.cors));
app.use(bodyParser.json({ limit: config.bodyParserLimit }));
app.use(express.static(path.join(__dirname, '../public')));
app.use(logger);

// Funcție pentru a găsi toate IP-urile disponibile
function getAllNetworkInterfaces() {
    const interfaces = os.networkInterfaces();
    const addresses = [];
    
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            // Skip internal and non-IPv4 addresses
            if (iface.family === 'IPv4' && !iface.internal) {
                addresses.push({
                    address: iface.address,
                    netmask: iface.netmask,
                    interface: name
                });
            }
        }
    }
    return addresses;
}

// Root endpoint
app.get('/', (req, res) => {
    res.status(200).json({ 
        message: 'Smart Messages App API',
        version: '1.0.0',
        status: 'running',
        endpoints: {
            health: '/healthz',
            api: '/api',
            serverInfo: '/api/server-info'
        }
    });
});

// Health check endpoint
app.get('/healthz', (req, res) => {
    res.status(200).json({ 
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Server info endpoint
app.get('/api/server-info', (req, res) => {
    const networkInterfaces = getAllNetworkInterfaces();
    const port = process.env.PORT || 3000;
    const isProduction = process.env.NODE_ENV === 'production';
    
    res.json({
        interfaces: networkInterfaces.map(iface => ({
            ip: iface.address,
            interface: iface.interface
        })),
        port: port,
        serverUrls: networkInterfaces.map(iface => `http://${iface.address}:${port}`),
        isProduction: isProduction,
        renderIp: isProduction ? ['18.156.158.53', '18.156.42.200', '52.59.103.54'] : null
    });
});

// Routes
app.use('/api', chatRoutes);

// Error handling
app.use(errorHandler);

module.exports = app; 