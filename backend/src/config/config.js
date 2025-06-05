require('dotenv').config();

module.exports = {
    port: process.env.PORT || 3000,
    aiApiKey: process.env.OPENROUTER_API_KEY,
    openRouterApi: {
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: process.env.OPENROUTER_API_KEY,
        model: "meta-llama/llama-4-scout:free",
        temperature: 0.7,
        // maxTokens: 800
    },
    tokenPrefixes: {
        speaker: 'user',
        message: 'p'
    },
    cors: {
        origin: '*',
        methods: ['GET', 'POST', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With'],
        credentials: true,
        maxAge: 86400, // Cache preflight requests for 24 hours
        preflightContinue: false,
        optionsSuccessStatus: 204
    }
};
