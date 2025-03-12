const summarizeService = require('../services/summarizeService');

exports.generateSummary = async (req, res, next) => {
    try {
        const { messages } = req.body;
        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ error: 'Mesajele sunt necesare și trebuie să fie un array.' });
        }
        // Apelează serviciul de sumarizare
        const summary = await summarizeService.summarizeMessages(messages);
        // Stochează rezultatul în res.locals pentru ca middleware-ul de criptare să-l preia
        res.locals.summary = summary;
        next();
    } catch (error) {
        next(error);
    }
};


// pt a trimite direct raspunsul, fara middleware:
// const summarizeService = require('../services/summarizeService');

// exports.generateSummary = async (req, res, next) => {
//     try {
//         const { messages } = req.body;
//         if (!messages || !Array.isArray(messages)) {
//             return res.status(400).json({ error: 'Mesajele sunt necesare și trebuie să fie un array.' });
//         }
//         // Apelează serviciul de sumarizare
//         const summary = await summarizeService.summarizeMessages(messages);
//         // Trimite răspunsul direct
//         return res.json({ summary: summary });
//     } catch (error) {
//         next(error);
//     }
// };
