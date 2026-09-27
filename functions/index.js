const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// Import controllers
const ttsController = require("./controllers/tts.controller");

// Export Firebase Cloud Functions
exports.textToSpeech = functions.https.onRequest(ttsController.textToSpeech);

