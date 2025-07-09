const logger = require('./loggerService');
const nlp = require('compromise');

// Prefix folosit pentru a genera tokenuri unice de tip "Utilizator1",
// "Utilizator2" etc. Aceste tokenuri vor fi tratate ca nume reale de persoană
// de către modelul AI.
const PSEUDONYM_PREFIX = 'Utilizator';

class NameAnonymizer {
  constructor() {
    this.speakerMap = new Map(); // original name -> pseudonym
    this.speakerTokenMap = new Map(); // pseudonym -> original name
    // Contor folosit pentru a genera tokenuri unice
    this.pseudonymIndex = 0;
  }

  _nextPseudonym() {
    this.pseudonymIndex += 1;
    return `${PSEUDONYM_PREFIX}${this.pseudonymIndex}`;
  }

  _generateSpeakerToken(name) {
    const pseudonym = this._nextPseudonym();
    this.speakerMap.set(name, pseudonym);
    this.speakerTokenMap.set(pseudonym, name);
    logger.debug(`Anonymized speaker "${name}" as pseudonym "${pseudonym}"`);
    return pseudonym;
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

    // gather all speaker names and pregenerate pseudonyms
    messages.forEach(msg => {
      const name = extractName(msg);
      if (name && !this.speakerMap.has(name)) {
        this._generateSpeakerToken(name);
      }
    });

    const words = {};
    this.speakerMap.forEach((pseudo, name) => {
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
    return messages.map(msg => {
      this.speakerTokenMap.forEach((original, pseudo) => {
        const regex = new RegExp(pseudo, 'g');
        msg = msg.replace(regex, original);
      });
      return msg;
    });
  }

  reset() {
    this.speakerMap.clear();
    this.speakerTokenMap.clear();
    this.pseudonymIndex = 0;
  }

  getMapping() {
    return {
      speakers: Object.fromEntries(this.speakerMap)
    };
  }
}

module.exports = new NameAnonymizer();
