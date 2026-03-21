const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const app = require('./app');
const config = require('./config/config');
const os = require('os');

dotenv.config();

const port = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

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

const networkInterfaces = getAllNetworkInterfaces();
const primaryIp = networkInterfaces[0]?.address || '127.0.0.1';

// Debug messages
console.log('\n🚀 Starting server...');
console.log('\n📋 Environment variables:');
console.log(`   - 🔌 PORT: ${port}`);
console.log(`   - 🌍 NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
console.log(`   - 📏 Gemini API Key length (din OPENROUTER_API_KEY): ${process.env.OPENROUTER_API_KEY?.length || 0}`);

if (!isProduction) {
    console.log('\n🌐 Network Interfaces:');
    networkInterfaces.forEach(iface => {
        console.log(`   - ${iface.interface}: ${iface.address} (${iface.netmask})`);
    });
}

// Start the server
const server = app.listen(port, '0.0.0.0', () => {
    console.log('✅ Server started successfully');
    console.log(`📡 Listening on port ${port}`);
    
    if (isProduction) {
        console.log('🚀 Running in production mode');
        console.log('🌐 Server accessible at: https://smart-messages-app.onrender.com');
    } else {
        console.log(`🔗 Server URL: http://localhost:${port}`);
        networkInterfaces.forEach(iface => {
            console.log(`🌐 Server accessible at: ${iface.address}:${port} (${iface.interface})`);
        });
        console.log('💻 Server is accessible from other devices on the network\n');
    }
});

// Handle server errors
server.on('error', (error) => {
    console.error('❌ Server error:', error);
});

// Handle client connections - only log in development
if (!isProduction) {
    server.on('connection', (socket) => {
        console.log(`🔌 New client connected from ${socket.remoteAddress}:${socket.remotePort}`);
    });
}

// Handle client disconnections
server.on('close', () => {
    console.log('❌ Server closed');
});
