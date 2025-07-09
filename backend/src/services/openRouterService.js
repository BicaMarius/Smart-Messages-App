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

    const response = await this._makeRequest(messages, eventDetectionPrompt, {
      responseFormat: { type: 'json_object' },
      maxTokens: 500,
      expectJson: true
    });
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

  async _makeRequest(messages, systemPrompt, options = {}) {
    logger.debug(`Se face request către OpenRouter API...`);
    logger.debug(`Număr mesaje procesate: ${messages.length}`);

    // Anonimizăm o singură dată pentru a păstra aceeași mapare la retry
    logger.debug('Anonimizare mesaje...');
    const anonymizedMessages = nameAnonymizer.anonymize(messages);
    logger.debug('Mesaje anonimizate');
    logger.debug(`Mesaje anonimizate:\n${anonymizedMessages.join('\n')}`);
    logger.debug(`Mapare nume: ${JSON.stringify(nameAnonymizer.getMapping())}`);

    const payload = {
      model: config.openRouterApi.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: anonymizedMessages.join('\n') }
      ],
      temperature: config.openRouterApi.temperature
    };

    if (options.responseFormat) {
      payload.response_format = options.responseFormat;
    }
    if (options.maxTokens) {
      payload.max_tokens = options.maxTokens;
    }

    for (let attempt = 1; attempt <= config.openRouterRetryCount; attempt++) {
      try {
        const response = await axios.post(
          `${this.baseUrl}/chat/completions`,
          payload,
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
        let deAnonymized = nameAnonymizer.deanonymize([aiMessage])[0];
        logger.debug(`Mesaj de-anonimizat:\n${deAnonymized}`);

        nameAnonymizer.reset();

        if (options.expectJson) {
          try {
            const { jsonrepair } = require('jsonrepair');
            const parsed = JSON.parse(deAnonymized);
            return parsed;
          } catch (err) {
            try {
              const { jsonrepair } = require('jsonrepair');
              return JSON.parse(jsonrepair(deAnonymized));
            } catch (err2) {
              logger.error('Eroare la parsarea răspunsului JSON');
              return deAnonymized;
            }
          }
        }

        return deAnonymized;
      } catch (error) {
        logger.error(
          `Eroare la apelul OpenRouter API (încercarea ${attempt}): ${error.message}`
        );
        if (attempt === config.openRouterRetryCount) {
          nameAnonymizer.reset();
          throw error;
        }
        const delay = 1000 * attempt;
        logger.warning(`Reîncercare după ${delay}ms...`);
        await new Promise(res => setTimeout(res, delay));
      }
    }
  }
}

module.exports = new OpenRouterService();
