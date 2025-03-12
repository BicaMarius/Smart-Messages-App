const express = require('express');
const router = express.Router();
const summarizeController = require('../controllers/summarizeController');
const encryptionMiddleware = require('../middlewares/encryptionMiddleware');


router.post(
  '/',
  encryptionMiddleware.decryptRequestBody,
  summarizeController.generateSummary,
  encryptionMiddleware.encryptResponseBody
);

module.exports = router;
