const axios = require('axios');
const config = require('../config/config');
const { summaryPrompt } = require('../config/summaryPrompt');
const { eventDetectionPrompt } = require('../config/eventDetectionPrompt');
const { askPrompt } = require('../config/askPrompt');
const logger = require('./loggerService');
const nameAnonymizer = require('./nameAnonymizer');

const MAX_RETRIES = 3;
const RETRY_BASE_DELAY = 1000; // ms

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
    let selected = messages;
    const limit = config.askMessageLimit;
    if (Number.isFinite(limit) && messages.length > limit) {
      logger.warn(
        `Număr mesaje (${messages.length}) depășește limita de ${limit}. Aplicăm trunchiere.`
      );
      selected = this._truncateMessages(messages, limit);
    }

    const context = selected.join('\n');
    const prompt = `${askPrompt}\n\nContext:\n${context}\n\nÎntrebare: ${question}`;
    return this._makeRequest([prompt], askPrompt);
  }

  _truncateMessages(messages, limit) {
    const dateRegex = /^(\d{1,2})\.(\d{1,2})\.(\d{4})/;
    const groups = [];
    let currentKey = null;
    let currentGroup = [];

    for (const msg of messages) {
      const match = msg.match(dateRegex);
      const key = match ? `${match[1]}.${match[2]}.${match[3]}` : currentKey || 'unknown';
      if (key !== currentKey) {
        if (currentGroup.length) groups.push(currentGroup);
        currentGroup = [];
        currentKey = key;
      }
      currentGroup.push(msg);
    }
    if (currentGroup.length) groups.push(currentGroup);

    const result = [];
    for (const group of groups) {
      if (result.length + group.length > limit) break;
      result.push(...group);
    }
    return result;
  }

  async _makeRequest(messages, systemPrompt) {
    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        logger.debug(`Se face request către OpenRouter API... încercarea ${attempt}`);
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
        if (attempt === MAX_RETRIES || (error.response && error.response.status < 500 && error.response.status !== 503)) {
          throw error;
        }
        const delay = RETRY_BASE_DELAY * Math.pow(2, attempt - 1);
        logger.warn(`Reîncercare în ${delay} ms...`);
        await new Promise(res => setTimeout(res, delay));
      }
    }
  }
}

module.exports = new OpenRouterService();
