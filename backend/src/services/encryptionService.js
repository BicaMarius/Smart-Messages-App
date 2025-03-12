const crypto = require('crypto');
const config = require('../config/config');

const algorithm = 'aes-256-cbc';
const key = crypto.scryptSync(config.encryptionKey, 'salt', 32); // generează o cheie de 32 bytes

exports.encrypt = (data) => {
    const jsonData = JSON.stringify(data);
    const iv = crypto.randomBytes(16); // vector de inițializare
    const cipher = crypto.createCipheriv(algorithm, key, iv);
    let encrypted = cipher.update(jsonData, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    // Returnează IV-ul și textul criptat, separate prin ":"
    return iv.toString('hex') + ':' + encrypted;
};

exports.decrypt = (encryptedData) => {
    const parts = encryptedData.split(':');
    const iv = Buffer.from(parts.shift(), 'hex');
    const encryptedText = parts.join(':');
    const decipher = crypto.createDecipheriv(algorithm, key, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return JSON.parse(decrypted);
};
