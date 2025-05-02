const axios = require('axios');
const config = require('../config/config');
const { summaryPrompt } = require('../config/summaryPrompt');
const { eventDetectionPrompt } = require('../config/eventDetectionPrompt');
const { askPrompt } = require('../config/askPrompt');
const logger = require('./loggerService');

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
              content: messages.join('\n')
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
      
      return response.data.choices[0].message.content;
    } catch (error) {
      logger.error(`Eroare la apelul OpenRouter API: ${error.message}`);
      throw error;
    }
  }
}

module.exports = new OpenRouterService(); 