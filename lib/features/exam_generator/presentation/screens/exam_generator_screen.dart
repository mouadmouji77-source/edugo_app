import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/exam.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/exam_providers.dart';
import '../widgets/exam_preview.dart';

class ExamGeneratorScreen extends ConsumerStatefulWidget {
  const ExamGeneratorScreen({super.key});

  @override
  ConsumerState<ExamGeneratorScreen> createState() => _ExamGeneratorScreenState();
}

enum ContentInputMode { pdf, text }

class _ExamGeneratorScreenState extends ConsumerState<ExamGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _examTitleController = TextEditingController();
  final _courseTextController = TextEditingController();
  
  ContentInputMode _inputMode = ContentInputMode.pdf;
  ExamDifficulty _difficulty = ExamDifficulty.medium;
  TotalScore _totalScore = TotalScore.twenty;
  int _numberOfQuestions = 10;
  
  Uint8List? _logoBytes;
  String? _logoBase64;
  Uint8List? _pdfBytes;
  String? _pdfFileName;
  
  bool _isGenerating = false;
  Exam? _generatedExam;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _examTitleController.dispose();
    _courseTextController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _logoBytes = result.files.single.bytes;
        _logoBase64 = base64Encode(_logoBytes!);
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pdfBytes = result.files.single.bytes;
        _pdfFileName = result.files.single.name;
      });
    }
  }

  Future<void> _generateExam() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate content based on input mode
    if (_inputMode == ContentInputMode.pdf && _pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a PDF course first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_inputMode == ContentInputMode.text && _courseTextController.text.length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 100 characters of course content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final exam = await ref.read(examControllerProvider).generateExam(
        pdfBytes: _inputMode == ContentInputMode.pdf ? _pdfBytes : null,
        textContent: _inputMode == ContentInputMode.text ? _courseTextController.text : null,
        schoolName: _schoolNameController.text,
        examTitle: _examTitleController.text,
        logoBase64: _logoBase64,
        difficulty: _difficulty,
        totalScore: _totalScore,
        numberOfQuestions: _numberOfQuestions,
      );

      setState(() {
        _generatedExam = exam;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating exam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Generator'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isGenerating,
        loadingText: 'Generating exam questions...',
        child: _generatedExam != null
            ? ExamPreview(
                exam: _generatedExam!,
                onBack: () => setState(() => _generatedExam = null),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Exam Generator',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload your course PDF and generate professional exams with AI',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Course Content Section
                Text(
                  '1. Course Content',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Input mode selection
                SegmentedButton<ContentInputMode>(
                  segments: const [
                    ButtonSegment(
                      value: ContentInputMode.pdf,
                      label: Text('Upload PDF'),
                      icon: Icon(Icons.picture_as_pdf),
                    ),
                    ButtonSegment(
                      value: ContentInputMode.text,
                      label: Text('Write Text'),
                      icon: Icon(Icons.edit_note),
                    ),
                  ],
                  selected: {_inputMode},
                  onSelectionChanged: (selected) {
                    setState(() => _inputMode = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                
                // PDF Upload or Text Input based on mode
                if (_inputMode == ContentInputMode.pdf)
                  InkWell(
                    onTap: _pickPdf,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _pdfBytes != null
                              ? Colors.green
                              : Theme.of(context).colorScheme.outline,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _pdfBytes != null
                            ? Colors.green.withOpacity(0.1)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _pdfBytes != null
                                ? Icons.check_circle
                                : Icons.upload_file,
                            size: 32,
                            color: _pdfBytes != null ? Colors.green : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _pdfFileName ?? 'Click to upload PDF course',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _pdfBytes != null ? Colors.green : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  TextFormField(
                    controller: _courseTextController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: 'Course Content',
                      hintText: 'Paste or write your course content here...',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    validator: (value) {
                      if (_inputMode == ContentInputMode.text && (value == null || value.length < 100)) {
                        return 'Please enter at least 100 characters of course content';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 32),

                // School Details Section
                Text(
                  '2. School Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _schoolNameController,
                  decoration: const InputDecoration(
                    labelText: 'School Name',
                    hintText: 'Enter your school name',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter school name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _examTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title',
                    hintText: 'Ex: Examen Final - Mathématiques',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter exam title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Logo Upload
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickLogo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _logoBytes != null
                                    ? Icons.check_circle
                                    : Icons.add_photo_alternate,
                                color: _logoBytes != null ? Colors.green : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _logoBytes != null
                                    ? 'Logo uploaded'
                                    : 'Upload School Logo (optional)',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_logoBytes != null) ...[
                      const SizedBox(width: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _logoBytes!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // Exam Settings Section
                Text(
                  '3. Exam Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Question Style (Difficulty - internal, not shown in PDF)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Question Style',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'This affects how questions are phrased.\nIt will NOT appear in the final exam.',
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ExamDifficulty>(
                          segments: const [
                            ButtonSegment(
                              value: ExamDifficulty.easy,
                              label: Text('Basic'),
                              icon: Icon(Icons.looks_one),
                            ),
                            ButtonSegment(
                              value: ExamDifficulty.medium,
                              label: Text('Standard'),
                              icon: Icon(Icons.looks_two),
                            ),
                            ButtonSegment(
                              value: ExamDifficulty.hard,
                              label: Text('Advanced'),
                              icon: Icon(Icons.looks_3),
                            ),
                          ],
                          selected: {_difficulty},
                          onSelectionChanged: (selected) {
                            setState(() => _difficulty = selected.first);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDifficultyDescription(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Total Score Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Score',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<TotalScore>(
                          segments: const [
                            ButtonSegment(
                              value: TotalScore.twenty,
                              label: Text('20 Points'),
                            ),
                            ButtonSegment(
                              value: TotalScore.hundred,
                              label: Text('100 Points'),
                            ),
                          ],
                          selected: {_totalScore},
                          onSelectionChanged: (selected) {
                            setState(() => _totalScore = selected.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Number of Questions Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Number of Questions',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _numberOfQuestions.toDouble(),
                                min: 3,
                                max: 20,
                                divisions: 17,
                                label: '$_numberOfQuestions questions',
                                onChanged: (value) {
                                  setState(() => _numberOfQuestions = value.round());
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_numberOfQuestions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Points per question: ${(_totalScore == TotalScore.twenty ? 20 : 100) / _numberOfQuestions} pts',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _generateExam,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'Generate Exam',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDifficultyDescription() {
    switch (_difficulty) {
      case ExamDifficulty.easy:
        return 'Definition questions, direct recall, identification';
      case ExamDifficulty.medium:
        return 'Explanation questions, comparison, application';
      case ExamDifficulty.hard:
        return 'Analysis questions, evaluation, problem-solving';
    }
  }
}

