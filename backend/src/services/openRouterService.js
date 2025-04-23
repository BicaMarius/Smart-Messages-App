const axios = require('axios');
const config = require('../config/config');
const { systemInstruction } = require('../config/prompts');

class OpenRouterService {
  constructor() {
    this.baseUrl = config.openRouterApi.baseUrl;
    this.apiKey = config.openRouterApi.apiKey;
  }

  async generateSummary(messages) {
    console.log('Making request to OpenRouter API...');
    
    const response = await axios.post(
      `${this.baseUrl}/chat/completions`,
      {
        model: config.openRouterApi.model,
        messages: [
          {
            role: "system",
            content: systemInstruction
          },
          {
            role: "user",
            content: messages.join('\n')
          }
        ],
        temperature: config.openRouterApi.temperature,
        max_tokens: config.openRouterApi.maxTokens
      },
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'HTTP-Referer': 'http://localhost:3000',
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('OpenRouter API response received');
    console.log('Response status:', response.status);
    
    return response.data.choices[0].message.content;
  }
}

module.exports = new OpenRouterService(); 