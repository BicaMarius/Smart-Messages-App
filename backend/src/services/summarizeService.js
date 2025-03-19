const config = require('../config/config');

exports.summarizeMessages = async (messages) => {
  const prompt = `Te rog să generezi un sumar concis pentru următoarele mesaje:\n${messages.join('\n')}`;
  
  try {
    const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${config.aiApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: "deepseek/deepseek-r1-distill-qwen-32b:free",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ]
      })
    });

    if (!response.ok) {
      const errorDetails = await response.text();
      console.error(`Status Code: ${response.status}, Error Details: ${errorDetails}`);
      throw new Error(`Eroare la apelarea Openrouter API: ${response.status} - ${errorDetails}`);
    }

    const data = await response.json();
    const summary = data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content;
    return summary;
  } catch (error) {
    console.error("Eroare în summarizeMessages:", error);
    throw error;
  }
};
