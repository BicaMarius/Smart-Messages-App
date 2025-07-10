const openRouter = require('../services/openRouterService');
const eventsSvc = require('../services/eventDetectionService');
const logger = require('../services/loggerService');

class ChatController {
  async summarize(req, res) {
    try {
      const { messages } = req.body;
      logger.info('Primit request pentru **sumarizare**');
      logger.debug(`Număr mesaje: ${messages.length}`);
      logger.debug(`Primul   msg: ${messages[0]}`);
      logger.debug(`Ultimul  msg: ${messages[messages.length - 1]}`);

      const summaryRaw = await openRouter.generateSummary(messages);
      logger.success('Rezumat generat cu succes');
      logger.debug(`Rezumat (raw):\n${summaryRaw}`);

      const evRaw = await openRouter.detectEventsWithRetry(messages);
      logger.debug(`detectEvents › răspuns:\n${evRaw}`);

      const refDate = eventsSvc.getReferenceDate(messages);
      const { events } = await eventsSvc.extractEvents(evRaw, refDate);

      if (events.length) {
        events.forEach((e, i) =>
          logger.event(`${i + 1}. ${e.title} @ ${e.dateTime}`)
        );
      } else {
        logger.info('Nu s-au detectat evenimente');
      }

      res.json({
        summary: summaryRaw.replace(/^sumarizare:\s*/i, '').trim(),
        events
      });

    } catch (err) {
      logger.error(`Eroare în funcția summarize: ${err.message}`);
      res.status(500).json({ error: 'Eroare internă a serverului' });
    }
  }

  async askQuestion(req, res) {
    try {
      const { messages, question } = req.body;
      logger.info('Primit request pentru **întrebare**');
      logger.debug(`Întrebare: ${question}`);

      const answerRaw = await openRouter.askQuestion(messages, question);
      res.json({ answer: answerRaw.replace(/^răspuns:\s*/i, '').trim() });
    } catch (err) {
      logger.error(`Eroare în funcția askQuestion: ${err.message}`);
      res.status(500).json({ error: 'Eroare internă a serverului' });
    }
  }
}

module.exports = new ChatController();
