const axios = require('axios');
const config = require('../config/config');
const { summaryPrompt } = require('../config/summaryPrompt');
const { eventDetectionPrompt } = require('../config/eventDetectionPrompt');
const { askPrompt } = require('../config/askPrompt');
const logger = require('./loggerService');
const nameAnon = require('./nameAnonymizer');

class OpenRouterService {
  constructor() {
    this.baseUrl = config.openRouterApi.baseUrl;
    this.apiKey = config.openRouterApi.apiKey;
  }

  generateSummary = (msgs) => this._callOnce(msgs, summaryPrompt);

  async detectEventsWithRetry(messages, maxAttempts = 3) {
    for (let i = 0; i < maxAttempts; i++) {
      logger.debug(`detectEvents › încercarea ${i + 1}/${maxAttempts}`);
      try {
        const raw = await this._callOnce(messages, eventDetectionPrompt);

        // acceptăm doar răspunsuri care *încep* cu { pentru a evita “junk text”
        if (raw.trim().startsWith('{')) {
          return raw;
        }
        logger.warning('detectEvents › răspuns invalid – nu începe cu {');
      } catch (err) {
        const code = err.response?.status;
        if ([429, 502, 503, 504].includes(code) && i < maxAttempts - 1) {
          const wait = 1000 * (i + 1);                // back-off liniar (1s, 2s…)
          logger.warning(`OpenRouter ${code} – retry după ${wait}ms`);
          await new Promise(r => setTimeout(r, wait));
          continue;
        }
        throw err;
      }

      if (i < maxAttempts - 1) {
        const wait = 1000 * (i + 1);
        await new Promise(r => setTimeout(r, wait));
      }
    }
    throw new Error('Nu s-a putut obține un JSON valid pentru evenimente');
  }

  async askQuestion(messages, question) {
    let selected = messages;
    const limit = config.askMessageLimit;
    if (Number.isFinite(limit) && messages.length > limit) {
      logger.warning(
        `Număr mesaje (${messages.length}) depășește limita de ${limit}. Trunchiem.`
      );
      selected = this._truncate(messages, limit);
    }

    const context = selected.join('\n');
    const prompt = `${askPrompt}\n\nContext:\n${context}\n\nÎntrebare: ${question}`;
    return this._callOnce([prompt], askPrompt);
  }

  async _callOnce(messages, systemPrompt) {
    logger.debug(`OpenRouter › trimitem ${messages.length} mesaje`);


    const anonMsgs = nameAnon.anonymize(messages);
    logger.debug('Anonimizare completă');
    logger.debug(`Mapare: ${JSON.stringify(nameAnon.getMapping())}`);

    try {
      const res = await axios.post(
        `${this.baseUrl}/chat/completions`,
        {
          model: config.openRouterApi.model,
          temperature: config.openRouterApi.temperature,
          max_tokens: config.openRouterApi.maxTokens,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: anonMsgs.join('\n') }
          ]
        },
        {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'HTTP-Referer': '*',
            'Content-Type': 'application/json'
          },
          timeout: 30_000
        }
      );

      logger.debug(`Status răspuns: ${res.status}`);

      const aiRaw = res.data.choices[0].message.content;
      const clean = nameAnon.deanonymize([aiRaw])[0];

      logger.debug(`Raw AI message – ${clean.length} caractere`);
      return clean;
    } finally {
      nameAnon.reset();
    }
  }

  _truncate(msgs, limit) {
    const res = [];
    for (let i = msgs.length - 1; i >= 0 && res.length < limit; i--) {
      res.unshift(msgs[i]);
    }
    return res;
  }
}

module.exports = new OpenRouterService();
