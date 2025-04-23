const openRouterService = require('../services/openRouterService');
const eventDetectionService = require('../services/eventDetectionService');

class ChatController {
  async summarize(req, res) {
    try {
      const { messages } = req.body;
      console.log('Received request to summarize messages');
      console.log('Number of messages:', messages.length);
      console.log('First message:', messages[0]);
      console.log('Last message:', messages[messages.length - 1]);

      const aiResponse = await openRouterService.generateSummary(messages);
      console.log('Generated response:', aiResponse);

      const { summary, events } = eventDetectionService.extractEvents(aiResponse);

      // Debug: log detected events
      if (events.length > 0) {
        console.log(`Detected ${events.length} events:`);
        events.forEach((event, index) => {
          console.log(`${index + 1}. ${event.title}, date: ${event.dateTime}`);
        });
      } else {
        console.log('No events detected');
      }

      res.json({ 
        summary,
        events
      });
    } catch (error) {
      console.error('Error in summarize:', error);
      throw error;
    }
  }
}

module.exports = new ChatController(); 