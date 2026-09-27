import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Summary;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import '../../../../core/models/summary.dart';
import '../../../../services/tts_service.dart';

class SummaryContent extends StatefulWidget {
  final Summary summary;

  const SummaryContent({
    super.key,
    required this.summary,
  });

  @override
  State<SummaryContent> createState() => _SummaryContentState();
}

class _SummaryContentState extends State<SummaryContent> {
  bool _isSpeaking = false;
  bool _isGeneratingAudio = false;

  @override
  void dispose() {
    TTSService.stop();
    super.dispose();
  }

  /// Clean markdown and special characters for TTS
  String _cleanTextForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '') // Remove bold markers
        .replaceAll(RegExp(r'\*'), '') // Remove italic markers
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Remove headers
        .replaceAll(RegExp(r'•'), ', ') // Replace bullets
        .replaceAll(RegExp(r'-\s'), ', ') // Replace list items
        .replaceAll(RegExp(r'\n+'), '. ') // Replace newlines with pauses
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  /// Detect language from text
  String _detectLanguage(String text) {
    final sample = text.substring(0, text.length > 200 ? 200 : text.length).toLowerCase();
    
    // Check for Arabic
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(sample)) {
      return 'ar';
    }
    // Check for French
    if (RegExp(r'\b(le|la|les|un|une|des|est|sont|dans|pour|avec|sur)\b').hasMatch(sample)) {
      return 'fr';
    }
    return 'en';
  }

  /// Play text using Web Speech API
  void _toggleSpeak() async {
    if (_isSpeaking) {
      TTSService.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    final cleanText = _cleanTextForSpeech(widget.summary.content);
    final lang = _detectLanguage(cleanText);
    
    setState(() => _isSpeaking = true);
    
    try {
      await TTSService.speak(cleanText, lang);
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  /// Download summary as MP3 using Cloud Function TTS
  Future<void> _downloadAsMP3() async {
    setState(() => _isGeneratingAudio = true);

    try {
      final cleanText = _cleanTextForSpeech(widget.summary.content);
      final lang = _detectLanguage(cleanText);
      
      // Call Cloud Function for TTS
      final response = await http.post(
        Uri.parse(
          kIsWeb 
              ? 'http://127.0.0.1:5001/edugo-a78a0/us-central1/textToSpeech'
              : 'http://10.0.2.2:5001/edugo-a78a0/us-central1/textToSpeech'
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': cleanText,
          'language': lang,
          'title': widget.summary.title,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['audioBase64'] != null) {
          // Download the MP3 file
          final fileName = '${widget.summary.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_summary.mp3';
          TTSService.downloadAudio(data['audioBase64'], fileName);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('MP3 downloaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (data['error'] != null) {
          throw Exception(data['error']);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAudio = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.summary.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          // Metadata
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Created ${_formatDate(widget.summary.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              if (widget.summary.pdfUrl != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'From PDF',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Audio Controls Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.headphones,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Audio Options',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Listen Button
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 60) / 2,
                        child: FilledButton.icon(
                          onPressed: _toggleSpeak,
                          icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                          label: Text(_isSpeaking ? 'Stop' : 'Listen'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isSpeaking 
                                ? Colors.red 
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      // Download MP3 Button
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 60) / 2,
                        child: OutlinedButton.icon(
                          onPressed: _isGeneratingAudio ? null : _downloadAsMP3,
                          icon: _isGeneratingAudio 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(_isGeneratingAudio ? 'Generating...' : 'Download MP3'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Content with Markdown support
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: widget.summary.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                      strong: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      h1: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Keywords
          if (widget.summary.keywords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Terms',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.summary.keywords
                          .map((keyword) => Chip(
                                label: Text(keyword),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
