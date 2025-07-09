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
      logger.debug(`Răspuns evenimente: ${typeof eventsResponse === 'string' ? eventsResponse : JSON.stringify(eventsResponse)}`);

      // Procesăm evenimentele
      const referenceDate = eventDetectionService.getReferenceDate(messages);
      const { events } = await eventDetectionService.extractEvents(eventsResponse, referenceDate);

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

  async askQuestion(req, res) {
    try {
      const { messages, question } = req.body;
      logger.info('Primit request pentru întrebare');
      logger.debug(`Întrebare: ${question}`);
      logger.debug(`Număr mesaje: ${messages.length}`);
      logger.debug(`IP client: ${req.ip}`);
      logger.debug(`Headers: ${JSON.stringify(req.headers)}`);

      // Generăm răspunsul
      logger.ai('Inițializare generare răspuns...');
      const response = await openRouterService.askQuestion(messages, question);
      logger.success('Răspuns generat cu succes');
      logger.debug(`Răspuns generat: ${response}`);

      // Extragem răspunsul din formatul specificat
      const answer = response.replace('răspuns:', '').trim();

      res.json({ answer });
    } catch (error) {
      logger.error(`Eroare în funcția askQuestion: ${error.message}`);
      logger.error(`Stack trace: ${error.stack}`);
      res.status(500).json({ error: 'Eroare internă a serverului' });
    }
  }
}

module.exports = new ChatController(); 