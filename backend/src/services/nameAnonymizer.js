const logger = require('./loggerService');
const nlp = require('compromise');
const { tokenPrefixes } = require('../config/config');

class NameAnonymizer {
  constructor() {
    this.messageMap = new Map();
    this.messageTokenMap = new Map();
    this.knownNames = new Set();
  }

  _generateMessageToken(name) {
    const token = `${tokenPrefixes.message}${this.messageMap.size + 1}`;
    this.messageMap.set(name, token);
    this.messageTokenMap.set(token, name);
    logger.debug(`Anonymized text name "${name}" as token ${token}`);
    return token;
  }

  anonymize(messages) {
    const extractName = (line) => {
      const hyphen = line.indexOf(' - ');
      const colon = line.indexOf(':', hyphen !== -1 ? hyphen + 3 : 0);
      if (hyphen !== -1 && colon > hyphen) {
        return line.slice(hyphen + 3, colon).trim();
      }
      if (colon !== -1 && hyphen === -1) {
        return line.slice(0, colon).trim();
      }
      return null;
    };

    // gather all speaker names to improve person detection
    messages.forEach(msg => {
      const name = extractName(msg);
      if (name) {
        this.knownNames.add(name);
      }
    });
    const words = {};
    this.knownNames.forEach(n => {
      words[n] = 'Person';
    });
    nlp.addWords(words);

    return messages.map(originalMsg => {
      let msg = originalMsg;
      const name = extractName(msg);
      let textPart = msg;
      if (name) {
        const hyphen = msg.indexOf(' - ');
        const colonIndex = msg.indexOf(':', hyphen !== -1 ? hyphen + 3 : 0);
        if (colonIndex !== -1) {
          textPart = msg.slice(colonIndex + 1);
        } else {
          textPart = msg;
        }
      }

      const doc = nlp(textPart);
      doc.people().out('array').forEach(personName => {
        if (!this.messageMap.has(personName)) {
          this._generateMessageToken(personName);
        }
        const token = this.messageMap.get(personName);
        doc.match(personName).replaceWith(token);
      });

      if (name) {
        const hyphen = msg.indexOf(' - ');
        const colonIndex = msg.indexOf(':', hyphen !== -1 ? hyphen + 3 : 0);
        if (colonIndex !== -1) {
          msg = msg.slice(0, colonIndex + 1) + doc.text();
        } else {
          msg = doc.text();
        }
      } else {
        msg = doc.text();
      }

      return msg;
    });
  }

  deanonymize(messages) {
    const messageRegex = new RegExp(`${tokenPrefixes.message}\\d+`, 'g');
    return messages.map(msg => msg.replace(messageRegex, token => this.messageTokenMap.get(token) || token));
  }

  reset() {
    // no speaker maps to reset
    this.messageMap.clear();
    this.messageTokenMap.clear();
    this.knownNames.clear();
  }

  getMapping() {
    return {
      messages: Object.fromEntries(this.messageMap)
    };
  }
}

module.exports = new NameAnonymizer();
