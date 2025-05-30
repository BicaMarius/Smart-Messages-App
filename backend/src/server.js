const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const app = require('./app');
const config = require('./config/config');
const os = require('os');

dotenv.config();

const port = process.env.PORT || 3000;

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
console.log(`   - 📏 OpenRouter API Key length: ${process.env.OPENROUTER_API_KEY?.length || 0}`);
console.log('\n🌐 Network Interfaces:');
networkInterfaces.forEach(iface => {
    console.log(`   - ${iface.interface}: ${iface.address} (${iface.netmask})`);
});

console.log('\n🌐 Server will listen on all network interfaces');

// Adăugăm un endpoint pentru a obține toate IP-urile serverului
app.get('/api/server-info', (req, res) => {
    res.json({
        interfaces: networkInterfaces.map(iface => ({
            ip: iface.address,
            interface: iface.interface
        })),
        port: port,
        serverUrls: networkInterfaces.map(iface => `http://${iface.address}:${port}`)
    });
});

// Start the server
const server = app.listen(port, '0.0.0.0', () => {
    console.log('✅ Server started successfully');
    console.log(`📡 Listening on port ${port}`);
    console.log(`🔗 Server URL: http://localhost:${port}`);
    networkInterfaces.forEach(iface => {
        console.log(`🌐 Server accessible at: ${iface.address}:${port} (${iface.interface})`);
    });
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
