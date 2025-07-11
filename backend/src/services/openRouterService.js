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
    const MAX_RETRIES = 3;
    let lastError = null;

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        logger.debug(`Se face request către OpenRouter API (încercarea ${attempt}/${MAX_RETRIES})...`);
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
            temperature: config.openRouterApi.temperature || 0.2,
            max_tokens: 2000, // Adăugăm limite pentru tokens
            top_p: 0.8,
          },
          {
            headers: {
              'Authorization': `Bearer ${this.apiKey}`,
              'HTTP-Referer': '*',
              'Content-Type': 'application/json'
            },
            timeout: 30000 // 30 secunde timeout
          }
        );

        logger.debug('Răspuns primit de la OpenRouter API');
        logger.debug(`Status răspuns: ${response.status}`);

        const aiMessage = response.data.choices[0].message.content;

        // LOG IMPORTANT: Afișăm răspunsul brut de la AI
        logger.debug(`Răspuns brut de la AI:\n${aiMessage}`);

        // Verificăm dacă răspunsul este incomplet
        if (!aiMessage || aiMessage.trim() === '') {
          throw new Error('Răspuns gol de la AI');
        }

        // Pentru detectarea evenimentelor, verificăm dacă JSON-ul este valid
        if (systemPrompt.includes('evenimente')) {
          if (!this._isValidEventResponse(aiMessage)) {
            throw new Error(`Răspuns invalid pentru evenimente: ${aiMessage}`);
          }
        }

        const deAnonymized = nameAnonymizer.deanonymize([aiMessage])[0];
        logger.debug(`Mesaj de-anonimizat:\n${deAnonymized}`);

        nameAnonymizer.reset();

        return deAnonymized;
      } catch (error) {
        lastError = error;
        logger.error(`Eroare la apelul OpenRouter API (încercarea ${attempt}/${MAX_RETRIES}): ${error.message}`);

        if (attempt === MAX_RETRIES) {
          break;
        }

        // Așteptăm înainte de următoarea încercare
        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
    }

    logger.error(`Toate încercările au eșuat. Ultima eroare: ${lastError?.message}`);
    throw lastError;
  }

  _isValidEventResponse(response) {
    try {
      const trimmed = response.trim();

      // Verificăm dacă începe cu { și se termină cu }
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        logger.warn('Răspunsul nu este un JSON valid (nu începe cu { sau nu se termină cu })');
        return false;
      }

      // Încercăm să parsăm JSON-ul
      const parsed = JSON.parse(trimmed);

      // Verificăm dacă există proprietatea "evenimente"
      if (!parsed.hasOwnProperty('evenimente')) {
        logger.warn('Răspunsul nu conține proprietatea "evenimente"');
        return false;
      }

      // Verificăm dacă "evenimente" este un array
      if (!Array.isArray(parsed.evenimente)) {
        logger.warn('Proprietatea "evenimente" nu este un array');
        return false;
      }

      logger.debug('Răspunsul JSON pentru evenimente este valid');
      return true;
    } catch (error) {
      logger.warn(`Eroare la validarea răspunsului JSON: ${error.message}`);
      return false;
    }
  }
}

module.exports = new OpenRouterService();