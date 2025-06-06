const logger = require('./loggerService');
const nlp = require('compromise');
const { tokenPrefixes } = require('../config/config');

class NameAnonymizer {
  constructor() {
    this.messageMap = new Map();
    this.messageTokenMap = new Map();
    this.speakerMap = new Map();
    this.speakerTokenMap = new Map();
    this.knownNames = new Set();
  }

  _generateMessageToken(name) {
    const token = `${tokenPrefixes.message}${this.messageMap.size + 1}`;
    this.messageMap.set(name, token);
    this.messageTokenMap.set(token, name);
    logger.debug(`Anonymized text name "${name}" as token ${token}`);
    return token;
  }

  _generateSpeakerToken(name) {
    const token = `${tokenPrefixes.speaker}${this.speakerMap.size + 1}`;
    this.speakerMap.set(name, token);
    this.speakerTokenMap.set(token, name);
    logger.debug(`Anonymized speaker "${name}" as token ${token}`);
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

    // gather all speaker names
    messages.forEach(msg => {
      const name = extractName(msg);
      if (name && !this.speakerMap.has(name)) {
        this._generateSpeakerToken(name);
      }
    });
    const words = {};
    this.speakerMap.forEach((token, name) => {
      words[name] = 'Person';
    });
    nlp.addWords(words);

    return messages.map(originalMsg => {
      let msg = originalMsg;
      const name = extractName(msg);
      let textPart = msg;
      let prefix = '';
      if (name) {
        const hyphen = msg.indexOf(' - ');
        const colonIndex = msg.indexOf(':', hyphen !== -1 ? hyphen + 3 : 0);
        if (colonIndex !== -1) {
          prefix = msg.slice(0, colonIndex + 1);
          textPart = msg.slice(colonIndex + 1);
        }
      }

      const doc = nlp(textPart);
      this.speakerMap.forEach((token, speakerName) => {
        doc.match(speakerName).replaceWith(token);
      });

      if (name) {
        const token = this.speakerMap.get(name);
        msg = prefix.replace(name, token) + doc.text();
      } else {
        msg = doc.text();
      }

      return msg;
    });
  }

  deanonymize(messages) {
    const messageRegex = new RegExp(`${tokenPrefixes.message}\\d+`, 'g');
    const speakerRegex = new RegExp(`${tokenPrefixes.speaker}\\d+`, 'g');
    return messages.map(msg =>
      msg
        .replace(speakerRegex, token => this.speakerTokenMap.get(token) || token)
        .replace(messageRegex, token => this.messageTokenMap.get(token) || token)
    );
  }

  reset() {
    this.speakerMap.clear();
    this.speakerTokenMap.clear();
    this.messageMap.clear();
    this.messageTokenMap.clear();
    this.knownNames.clear();
  }

  getMapping() {
    return {
      messages: Object.fromEntries(this.messageMap),
      speakers: Object.fromEntries(this.speakerMap)
    };
  }
}

module.exports = new NameAnonymizer();
