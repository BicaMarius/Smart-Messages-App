require('dotenv').config();

module.exports = {
    port: process.env.PORT || 3000,
    aiApiKey: process.env.OPENROUTER_API_KEY,
    openRouterApi: {
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: process.env.OPENROUTER_API_KEY,
        model: "deepseek/deepseek-r1-0528:free",
        temperature: 0.3,
        maxTokens: 1000
    },
    askMessageLimit: process.env.ASK_MESSAGE_LIMIT
        ? parseInt(process.env.ASK_MESSAGE_LIMIT, 10)
        : Infinity,
    bodyParserLimit: process.env.BODY_PARSER_LIMIT || '10mb',
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
