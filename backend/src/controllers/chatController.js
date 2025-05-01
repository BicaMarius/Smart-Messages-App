const openRouterService = require('../services/openRouterService');
const eventDetectionService = require('../services/eventDetectionService');
const logger = require('../services/loggerService');

class ChatController {
  async summarize(req, res) {
    try {
      const { messages } = req.body;
      logger.info('Primit request pentru sumarizare mesaje');
      logger.debug(`Număr mesaje: ${messages.length}`);
      logger.debug(`Primul mesaj: ${messages[0]}`);
      logger.debug(`Ultimul mesaj: ${messages[messages.length - 1]}`);

      // Generăm rezumatul
      logger.ai('Inițializare generare rezumat...');
      const summaryResponse = await openRouterService.generateSummary(messages);
      logger.success('Rezumat generat cu succes');
      logger.debug(`Rezumat generat: ${summaryResponse}`);

      // Detectăm evenimentele
      logger.ai('Inițializare detectare evenimente...');
      const eventsResponse = await openRouterService.detectEvents(messages);
      logger.success('Evenimente detectate cu succes');
      logger.debug(`Răspuns evenimente: ${eventsResponse}`);

      // Procesăm evenimentele
      const { events } = await eventDetectionService.extractEvents(eventsResponse);

      // Logăm evenimentele detectate
      if (events.length > 0) {
        logger.event(`S-au detectat ${events.length} evenimente:`);
        events.forEach((event, index) => {
          logger.event(`${index + 1}. ${event.title}, data: ${event.dateTime}`);
        });
      } else {
        logger.info('Nu s-au detectat evenimente');
      }

      res.json({ 
        summary: summaryResponse.replace('sumarizare:', '').trim(),
        events
      });
    } catch (error) {
      logger.error(`Eroare în funcția summarize: ${error.message}`);
      res.status(500).json({ error: 'Eroare internă a serverului' });
    }
  }
}

module.exports = new ChatController(); 