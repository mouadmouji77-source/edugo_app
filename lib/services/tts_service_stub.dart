import 'dart:async';

/// Text-to-Speech service stub for non-web platforms
class TTSService {
  static bool get isSupported => false;

  static Future<void> speak(String text, String language) async {
    // TODO: Implement mobile TTS using flutter_tts or similar
    print('TTS not implemented for this platform');
  }

  static void stop() {
    // No-op
  }

  static bool get isSpeaking => false;

  static void downloadAudio(String base64Audio, String fileName) {
    print('Download audio not implemented for this platform');
  }

  static void downloadAsText(String text, String fileName) {
    print('Download text not implemented for this platform');
  }
}
