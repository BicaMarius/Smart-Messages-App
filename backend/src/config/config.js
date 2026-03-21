require('dotenv').config();

module.exports = {
    port: process.env.PORT || 3000,
    aiApiKey: process.env.OPENROUTER_API_KEY,
    aiProvider: {
        provider: 'google-gemini',
        model: 'gemini-2.5-flash-lite',
        temperature: 0.3,
        maxTokens: 2000
    },
    /*
    Configurația veche OpenRouter rămâne aici comentată pentru fallback rapid dacă vei avea din nou nevoie.
    openRouterApi: {
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: process.env.OPENROUTER_API_KEY,
        model: 'meta-llama/llama-3.3-70b-instruct:free',
        temperature: 0.3,
        maxTokens: 1000
    },
    */
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
