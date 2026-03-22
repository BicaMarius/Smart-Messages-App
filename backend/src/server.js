const dotenv = require('dotenv');
const app = require('./app');
const os = require('os');

dotenv.config();

const port = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

function getAllNetworkInterfaces() {
    const interfaces = os.networkInterfaces();
    const addresses = [];
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                addresses.push({ address: iface.address, netmask: iface.netmask, interface: name });
            }
        }
    }
    return addresses;
}

const networkInterfaces = getAllNetworkInterfaces();

console.log('\n🚀 Starting server...');
console.log('\n📋 Environment variables:');
console.log(`   - 🔌 PORT: ${port}`);
console.log(`   - 🌍 NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
console.log(`   - 🔑 Gemini API Key length: ${process.env.GEMINI_API_KEY?.length || 0}`);

if (!isProduction) {
    console.log('\n🌐 Network Interfaces:');
    networkInterfaces.forEach(iface => {
        console.log(`   - ${iface.interface}: ${iface.address} (${iface.netmask})`);
    });
}

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

server.on('error', (error) => { console.error('❌ Server error:', error); });

if (!isProduction) {
    server.on('connection', (socket) => {
        console.log(`🔌 New client connected from ${socket.remoteAddress}:${socket.remotePort}`);
    });
}

server.on('close', () => { console.log('❌ Server closed'); });