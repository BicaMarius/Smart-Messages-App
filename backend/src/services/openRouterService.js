const axios = require('axios');
const config = require('../config/config');
const { summaryPrompt } = require('../config/summaryPrompt');
const { eventDetectionPrompt } = require('../config/eventDetectionPrompt');
const { askPrompt } = require('../config/askPrompt');
const logger = require('./loggerService');
const nameAnonymizer = require('./nameAnonymizer');

class OpenRouterService {
  constructor() {
    this.baseUrl = config.aiProvider.baseUrl;
    this.apiKey = config.aiProvider.apiKey;
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
      logger.warning(
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
        logger.debug(`Se face request către Gemini API (încercarea ${attempt}/${MAX_RETRIES})...`);
        logger.debug(`Model: ${config.aiProvider.model}`);
        logger.debug(`Număr mesaje procesate: ${messages.length}`);

        logger.debug('Anonimizare mesaje...');
        const anonymizedMessages = nameAnonymizer.anonymize(messages);
        logger.debug(`Mapare nume: ${JSON.stringify(nameAnonymizer.getMapping())}`);

        const requestPayload = {
          systemInstruction: {
            parts: [{ text: systemPrompt }]
          },
          contents: [
            {
              role: 'user',
              parts: [{ text: anonymizedMessages.join('\n') }]
            }
          ],
          generationConfig: {
            temperature: config.aiProvider.temperature || 0.3,
            maxOutputTokens: config.aiProvider.maxTokens || 2000,
            topP: 0.8
          }
        };

        const response = await axios.post(
          `${this.baseUrl}/models/${config.aiProvider.model}:generateContent`,
          requestPayload,
          {
            headers: {
              'x-goog-api-key': this.apiKey,
              'Content-Type': 'application/json'
            },
            timeout: 30000
          }
        );

        logger.debug(`Status răspuns: ${response.status}`);

        const aiMessage = response.data?.candidates?.[0]?.content?.parts
          ?.map(p => p?.text)
          .filter(Boolean)
          .join('\n')
          .trim();

        if (!aiMessage) {
          throw new Error('Răspuns gol de la Gemini');
        }

        logger.debug(`Răspuns brut de la AI:\n${aiMessage}`);

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

        if (error.response) {
          logger.error(`HTTP ${error.response.status} de la Gemini API`);
          logger.error(`Detalii eroare: ${JSON.stringify(error.response.data)}`);

          // 401/403 = cheie greșită, nu reîncercăm
          if (error.response.status === 401 || error.response.status === 403) {
            logger.error('Eroare de autentificare - verifică GEMINI_API_KEY în Render');
            break;
          }

          // 429 = rate limit, nu reîncercăm
          if (error.response.status === 429) {
            logger.error('Rate limit atins (429) - oprire imediată');
            break;
          }

          // 400 = request invalid
          if (error.response.status === 400) {
            logger.error('Request invalid (400) - oprire imediată');
            break;
          }
        } else {
          logger.error(`Eroare (încercarea ${attempt}/${MAX_RETRIES}): ${error.message}`);
        }

        if (attempt === MAX_RETRIES) break;

        await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
      }
    }

    logger.error(`Toate încercările au eșuat. Ultima eroare: ${lastError?.message}`);
    throw lastError;
  }

  _isValidEventResponse(response) {
    try {
      const trimmed = response.trim();

      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        logger.warning('Răspunsul nu este un JSON valid');
        return false;
      }

      const parsed = JSON.parse(trimmed);

      if (!parsed.hasOwnProperty('evenimente')) {
        logger.warning('Răspunsul nu conține proprietatea "evenimente"');
        return false;
      }

      if (!Array.isArray(parsed.evenimente)) {
        logger.warning('Proprietatea "evenimente" nu este un array');
        return false;
      }

      logger.debug('Răspunsul JSON pentru evenimente este valid');
      return true;
    } catch (error) {
      logger.warning(`Eroare la validarea răspunsului JSON: ${error.message}`);
      return false;
    }
  }
}

module.exports = new OpenRouterService();