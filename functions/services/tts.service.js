const fetch = require("node-fetch");

/**
 * Map language codes to voice names
 */
const VOICE_MAP = {
  'fr': 'fr-FR',
  'ar': 'ar-XA',
  'en': 'en-US'
};

/**
 * Generate text-to-speech audio from text
 * @param {string} text - Text to convert to speech
 * @param {string} language - Language code (fr, ar, en)
 * @returns {Promise<Object>} - {audioBase64: string, language: string}
 */
async function generateTTS(text, language = 'en') {
  const langCode = VOICE_MAP[language] || 'en-US';
  
  // Clean and limit text (Google TTS has limits)
  let cleanText = text
    .replace(/[*#_~`]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  
  // Limit to 5000 characters for TTS
  if (cleanText.length > 5000) {
    cleanText = cleanText.substring(0, 5000) + '...';
  }

  const chunks = [];
  const chunkSize = 200; // Google TTS limit per request
  
  for (let i = 0; i < cleanText.length; i += chunkSize) {
    chunks.push(cleanText.substring(i, i + chunkSize));
  }

  // Fetch audio for each chunk
  const audioChunks = [];
  
  for (const chunk of chunks) {
    const ttsChunkUrl = `https://translate.google.com/translate_tts?ie=UTF-8&tl=${language || 'en'}&client=tw-ob&q=${encodeURIComponent(chunk)}`;
    
    try {
      const audioResponse = await fetch(ttsChunkUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      });
      
      if (audioResponse.ok) {
        const audioBuffer = await audioResponse.buffer();
        audioChunks.push(audioBuffer);
      }
    } catch (chunkError) {
      console.error("Error fetching chunk:", chunkError.message);
    }
  }

  if (audioChunks.length === 0) {
    throw new Error("TTS service temporarily unavailable");
  }

  // Combine all audio chunks
  const combinedBuffer = Buffer.concat(audioChunks);
  const audioBase64 = combinedBuffer.toString('base64');

  return {
    audioBase64,
    language: langCode
  };
}

module.exports = {
  generateTTS
};

