import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/course_input_providers.dart';

class CourseInputScreen extends ConsumerStatefulWidget {
  const CourseInputScreen({super.key});

  @override
  ConsumerState<CourseInputScreen> createState() => _CourseInputScreenState();
}

class _CourseInputScreenState extends ConsumerState<CourseInputScreen> {
  final _titleController = TextEditingController();
  final _quillController = QuillController.basic();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final content = _quillController.document.toPlainText().trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final summaryId = await ref.read(courseInputControllerProvider).createSummaryFromText(
            title: _titleController.text.trim(),
            content: content,
          );
      
      if (mounted) {
        context.go('/summary/$summaryId');
      }
    } catch (e) {
      if (mounted) {
        // Suppress displaying raw 500 errors to the user, show a friendly message instead
        final errorMessage = e.toString();
        final displayMessage = errorMessage.contains('500') 
            ? 'Service unavailable momentarily. Please try again later.' 
            : 'Error generating summary: $errorMessage';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Course'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _generateSummary,
            child: const Text('Generate Summary'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Generating summary...',
        child: Column(
          children: [
            // Title Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  hintText: 'Enter the title of your course',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            
            // Editor Toolbar
            QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showListNumbers: true,
                showListBullets: true,
                showHeaderStyle: true,
                showQuote: true,
                showLink: false,
                showIndent: true,
                showInlineCode: true,
                showColorButton: false,
                showBackgroundColorButton: false,
                showFontFamily: false,
                showFontSize: false,
              ),
            ),
            
            // Editor
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QuillEditor.basic(
                  controller: _quillController,
                  config: const QuillEditorConfig(
                    placeholder: 'Start writing your course content here...',
                    padding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            
            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateSummary,
                      child: const Text('Generate Summary'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
