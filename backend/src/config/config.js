require('dotenv').config();

module.exports = {
    port: process.env.PORT || 3000,
    encryptionKey: process.env.ENCRYPTION_KEY,
    aiApiKey: process.env.OPENROUTER_API_KEY,
    openRouterApi: {
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: process.env.OPENROUTER_API_KEY,
        model: "meta-llama/llama-4-scout:free",
        temperature: 0.7,
        // maxTokens: 800
    },
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
        allowedHeaders: ['Content-Type']
    }
};
