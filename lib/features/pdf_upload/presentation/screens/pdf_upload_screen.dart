import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/pdf_upload_providers.dart';

class PdfUploadScreen extends ConsumerStatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  ConsumerState<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends ConsumerState<PdfUploadScreen> {
  final _titleController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // Important for web - loads file bytes into memory
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
          if (_titleController.text.isEmpty) {
            _titleController.text = _selectedFile!.name.replaceAll('.pdf', '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final summaryId = await ref.read(pdfUploadControllerProvider).uploadAndProcessPdf(
            title: _titleController.text.trim(),
            file: _selectedFile!,
          );
      
      if (mounted) {
        context.go('/summary/$summaryId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing PDF: ${e.toString()}'),
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
        title: const Text('Upload PDF'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadAndProcess,
            child: const Text('Process'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Processing PDF and generating summary...',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  hintText: 'Enter the title for your course',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Upload Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_selectedFile == null) ...[
                            Icon(
                              Icons.upload_file_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Upload PDF File',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click to browse and select a PDF file to upload',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text('Choose PDF File'),
                            ),
                          ] else ...[
                            Icon(
                              Icons.picture_as_pdf,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFile!.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _selectedFile = null),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Remove'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('Replace'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
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
                      onPressed: _selectedFile != null && !_isLoading ? _uploadAndProcess : null,
                      child: const Text('Process PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
