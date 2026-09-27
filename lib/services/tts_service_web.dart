import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Text-to-Speech service for web platform
class TTSService {
  static bool _isSpeaking = false;
  static Timer? _checkTimer;

  /// Check if TTS is supported
  static bool get isSupported {
    try {
      return js.context.callMethod('eval', ['\'speechSynthesis\' in window']) == true;
    } catch (e) {
      return false;
    }
  }

  /// Speak text using Web Speech API
  static Future<void> speak(String text, String language) async {
    if (!isSupported) {
      throw Exception('Text-to-Speech is not supported in this browser');
    }

    // Stop any current speech
    stop();

    // Escape quotes in text
    final escapedText = text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ');

    // Map language codes
    String langCode;
    switch (language) {
      case 'fr':
        langCode = 'fr-FR';
        break;
      case 'ar':
        langCode = 'ar-SA';
        break;
      default:
        langCode = 'en-US';
    }

    try {
      js.context.callMethod('eval', ['''
        (function() {
          if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
            
            var utterance = new SpeechSynthesisUtterance("$escapedText");
            utterance.lang = "$langCode";
            utterance.rate = 0.9;
            utterance.pitch = 1;
            utterance.volume = 1;
            
            // Try to find a voice for the language
            var voices = window.speechSynthesis.getVoices();
            for (var i = 0; i < voices.length; i++) {
              if (voices[i].lang.startsWith("$language")) {
                utterance.voice = voices[i];
                break;
              }
            }
            
            window._ttsPlaying = true;
            
            utterance.onend = function() {
              window._ttsPlaying = false;
            };
            
            utterance.onerror = function(event) {
              console.error('TTS Error:', event.error);
              window._ttsPlaying = false;
            };
            
            window.speechSynthesis.speak(utterance);
          }
        })();
      ''']);

      _isSpeaking = true;

      // Create a completer to wait for speech to end
      final completer = Completer<void>();

      // Check periodically if speech ended
      _checkTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        try {
          final isPlaying = js.context.callMethod('eval', ['window._ttsPlaying === true']);
          if (isPlaying != true) {
            timer.cancel();
            _isSpeaking = false;
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        } catch (e) {
          timer.cancel();
          _isSpeaking = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      });

      // Timeout after 5 minutes max
      Future.delayed(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          stop();
          completer.complete();
        }
      });

      return completer.future;
    } catch (e) {
      _isSpeaking = false;
      rethrow;
    }
  }

  /// Stop speaking
  static void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isSpeaking = false;

    try {
      js.context.callMethod('eval', ['''
        if ('speechSynthesis' in window) {
          window.speechSynthesis.cancel();
          window._ttsPlaying = false;
        }
      ''']);
    } catch (e) {
      // Ignore errors during stop
    }
  }

  /// Check if currently speaking
  static bool get isSpeaking => _isSpeaking;

  /// Download audio as MP3 file
  static void downloadAudio(String base64Audio, String fileName) {
    try {
      final bytes = base64Decode(base64Audio);
      final blob = html.Blob([bytes], 'audio/mpeg');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';
      
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      
      // Cleanup URL after download
      Future.delayed(const Duration(seconds: 1), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      throw Exception('Failed to download audio: $e');
    }
  }

  /// Download text as a text file (fallback option)
  static void downloadAsText(String text, String fileName) {
    try {
      final bytes = utf8.encode(text);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';
      
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      
      Future.delayed(const Duration(seconds: 1), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      throw Exception('Failed to download text: $e');
    }
  }
}

