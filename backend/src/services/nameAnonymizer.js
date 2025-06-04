const logger = require('./loggerService');
const nlp = require('compromise');

class NameAnonymizer {
  constructor() {
    this.speakerMap = new Map();
    this.speakerTokenMap = new Map();
    this.messageMap = new Map();
    this.messageTokenMap = new Map();
  }

  _generateSpeakerToken(name) {
    const token = `user${this.speakerMap.size + 1}`;
    this.speakerMap.set(name, token);
    this.speakerTokenMap.set(token, name);
    logger.debug(`Anonymized speaker "${name}" as token ${token}`);
    return token;
  }

  _generateMessageToken(name) {
    const token = `p${this.messageMap.size + 1}`;
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

    // prepopulate speaker tokens
    messages.forEach(msg => {
      const name = extractName(msg);
      if (name && !this.speakerMap.has(name)) {
        this._generateSpeakerToken(name);
      }
    });

    return messages.map(originalMsg => {
      let msg = originalMsg;
      const name = extractName(msg);
      let textPart = msg;
      if (name) {
        const token = this.speakerMap.get(name);
        const hyphen = msg.indexOf(' - ');
        const colonIndex = msg.indexOf(':', hyphen !== -1 ? hyphen + 3 : 0);
        if (colonIndex !== -1) {
          textPart = msg.slice(colonIndex + 1);
          msg = `${msg.slice(0, colonIndex).replace(name, token)}:${textPart}`;
        } else {
          msg = msg.replace(name, token);
          textPart = msg;
        }
      }

      const doc = nlp(textPart);
      doc.match('#ProperNoun+').out('array').forEach(personName => {
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
    return messages.map(msg => {
      msg = msg.replace(/user\d+/g, token => this.speakerTokenMap.get(token) || token);
      msg = msg.replace(/p\d+/g, token => this.messageTokenMap.get(token) || token);
      return msg;
    });
  }

  reset() {
    this.speakerMap.clear();
    this.speakerTokenMap.clear();
    this.messageMap.clear();
    this.messageTokenMap.clear();
  }

  getMapping() {
    return {
      speakers: Object.fromEntries(this.speakerMap),
      messages: Object.fromEntries(this.messageMap)
    };
  }
}

module.exports = new NameAnonymizer();
