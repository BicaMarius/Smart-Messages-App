require('dotenv').config();

module.exports = {
    port: process.env.PORT || 3000,
    aiProvider: {
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: process.env.GEMINI_API_KEY,
        model: 'gemini-2.5-flash-lite',
        temperature: 0.3,
        maxTokens: 2000
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
        maxAge: 86400,
        preflightContinue: false,
        optionsSuccessStatus: 204
    }
};