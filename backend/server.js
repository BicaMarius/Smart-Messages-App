const app = require('./src/app');
const config = require('./src/config/config');

console.log('Starting server...');
console.log('Environment variables:');
console.log('- PORT:', config.port);
console.log('- OpenRouter API Key available:', !!config.openRouterApi.apiKey);
console.log('- OpenRouter API Key length:', config.openRouterApi.apiKey ? config.openRouterApi.apiKey.length : 0);
console.log('Server will listen on all network interfaces');

// Listen on all network interfaces
app.listen(config.port, '0.0.0.0', () => {
  console.log(`Server started successfully`);
  console.log(`Listening on port ${config.port}`);
  console.log(`Server URL: http://localhost:${config.port}`);
  console.log(`Server is accessible from other devices on the network`);
});
