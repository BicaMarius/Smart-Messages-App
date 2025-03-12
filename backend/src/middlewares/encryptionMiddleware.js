const encryptionService = require('../services/encryptionService');

// Middleware pentru decriptarea corpului request-ului
exports.decryptRequestBody = (req, res, next) => {
    try {
        // Dacă requestul conține 'encryptedData', decriptează-l
        if (req.body.encryptedData) {
            req.body = encryptionService.decrypt(req.body.encryptedData);
        }
        next();
    } catch (error) {
        next(error);
    }
};

// Middleware pentru criptarea corpului răspunsului
exports.encryptResponseBody = (req, res, next) => {
    try {
        if (res.locals.summary) {
            const encryptedResponse = encryptionService.encrypt({ summary: res.locals.summary });
            return res.json({ encryptedData: encryptedResponse });
        }
        next();
    } catch (error) {
        next(error);
    }
};
