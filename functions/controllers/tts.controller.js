const cors = require("cors")({origin: true});
const ttsService = require("../services/tts.service");

/**
 * Handle text-to-speech request
 */
async function textToSpeech(req, res) {
  cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).send({error: "Method Not Allowed"});
      }

      const {text, language, title} = req.body;
      if (!text) {
        return res.status(400).send({error: "Text is required"});
      }

      const result = await ttsService.generateTTS(text, language);

      res.status(200).send({
        audioBase64: result.audioBase64,
        title: title || "Summary",
        language: result.language
      });
    } catch (error) {
      console.error("Error in TTS:", error.message);
      res.status(200).send({
        error: "Failed to generate audio: " + error.message,
        audioBase64: null
      });
    }
  });
}

module.exports = {
  textToSpeech
};

