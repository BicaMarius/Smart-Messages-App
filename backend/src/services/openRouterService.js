const axios = require('axios');
const config = require('../config/config');
const { summaryPrompt } = require('../config/summaryPrompt');
const { eventDetectionPrompt } = require('../config/eventDetectionPrompt');
const { askPrompt } = require('../config/askPrompt');
const logger = require('./loggerService');
const nameAnonymizer = require('./nameAnonymizer');

class OpenRouterService {
  constructor() {
    this.baseUrl = config.openRouterApi.baseUrl;
    this.apiKey = config.openRouterApi.apiKey;
  }

  async generateSummary(messages) {
    logger.ai('Inițializare generare rezumat...');
    
    const response = await this._makeRequest(messages, summaryPrompt);
    logger.success('Rezumat generat cu succes');
    
    return response;
  }

  async detectEvents(messages) {
    logger.ai('Inițializare detectare evenimente...');
    
    const response = await this._makeRequest(messages, eventDetectionPrompt);
    logger.success('Evenimente detectate cu succes');
    
    return response;
  }

  async askQuestion(messages, question) {
    const context = messages.join('\n');
    const prompt = `${askPrompt}\n\nContext:\n${context}\n\nÎntrebare: ${question}`;
    return this._makeRequest([prompt], askPrompt);
  }

  async _makeRequest(messages, systemPrompt) {
    try {
      logger.debug(`Se face request către OpenRouter API...`);
      logger.debug(`Număr mesaje procesate: ${messages.length}`);

      logger.debug('Anonimizare mesaje...');
      const anonymizedMessages = nameAnonymizer.anonymize(messages);
      logger.debug('Mesaje anonimizate');
      logger.debug(`Mesaje anonimizate:\n${anonymizedMessages.join('\n')}`);
      logger.debug(`Mapare nume: ${JSON.stringify(nameAnonymizer.getMapping())}`);

      const response = await axios.post(
        `${this.baseUrl}/chat/completions`,
        {
          model: config.openRouterApi.model,
          messages: [
            {
              role: "system",
              content: systemPrompt
            },
            {
              role: "user",
              content: anonymizedMessages.join('\n')
            }
          ],
          temperature: config.openRouterApi.temperature,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'HTTP-Referer': '*',
            'Content-Type': 'application/json'
          }
        }
      );

      logger.debug('Răspuns primit de la OpenRouter API');
      logger.debug(`Status răspuns: ${response.status}`);

      const aiMessage = response.data.choices[0].message.content;
      const deAnonymized = nameAnonymizer.deanonymize([aiMessage])[0];
      logger.debug(`Mesaj de-anonimizat:\n${deAnonymized}`);

      nameAnonymizer.reset();

      return deAnonymized;
    } catch (error) {
      logger.error(`Eroare la apelul OpenRouter API: ${error.message}`);
      throw error;
    }
  }
}

module.exports = new OpenRouterService();
