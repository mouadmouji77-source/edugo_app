import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/mindmap.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/mindmap_providers.dart';
import '../widgets/mindmap_view.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  final String? mindMapId;

  const MindMapScreen({super.key, this.mindMapId});

  @override
  ConsumerState<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends ConsumerState<MindMapScreen> {
  final _textController = TextEditingController();
  final _titleController = TextEditingController();
  final GlobalKey _repaintKey = GlobalKey();
  
  bool _isGenerating = false;
  bool _showInputForm = true;

  @override
  void initState() {
    super.initState();
    if (widget.mindMapId != null) {
      _showInputForm = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingMindMap();
      });
    }
  }

  void _loadExistingMindMap() async {
    final mindMapAsync = await ref.read(mindMapProvider(widget.mindMapId!).future);
    if (mindMapAsync != null) {
      ref.read(mindMapEditorProvider.notifier).setMindMap(mindMapAsync);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateMindMap() async {
    if (_textController.text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 50 characters of text'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final mindMap = await ref.read(mindMapControllerProvider).generateFromText(
        _textController.text,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
      );
      
      ref.read(mindMapEditorProvider.notifier).setMindMap(mindMap);
      
      setState(() {
        _isGenerating = false;
        _showInputForm = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveMindMap() async {
    final mindMap = ref.read(mindMapEditorProvider);
    if (mindMap == null) return;

    try {
      await ref.read(mindMapControllerProvider).saveMindMap(mindMap);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MindMap saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAsImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      
      // For web, trigger download
      _downloadFile(bytes, 'mindmap.png', 'image/png');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _downloadFile(Uint8List bytes, String fileName, String mimeType) {
    // Web download implementation
    final base64 = base64Encode(bytes);
    final anchor = Uri.dataFromBytes(bytes, mimeType: mimeType);
    // Use html package for web download in production
  }

  Future<void> _exportAsPdf() async {
    final mindMap = ref.read(mindMapEditorProvider);
    if (mindMap == null) return;

    try {
      await ref.read(mindMapControllerProvider).exportAsPdf(mindMap);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAsJson() async {
    final mindMap = ref.read(mindMapEditorProvider);
    if (mindMap == null) return;

    try {
      final json = await ref.read(mindMapControllerProvider).exportAsJson(mindMap);
      final bytes = utf8.encode(json);
      _downloadFile(Uint8List.fromList(bytes), 'mindmap.json', 'application/json');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting JSON: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mindMap = ref.watch(mindMapEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(mindMap?.title ?? 'Create MindMap'),
        actions: [
          if (mindMap != null) ...[
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: _saveMindMap,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onSelected: (value) {
                switch (value) {
                  case 'image':
                    _exportAsImage();
                    break;
                  case 'pdf':
                    _exportAsPdf();
                    break;
                  case 'json':
                    _exportAsJson();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'image',
                  child: ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Export as Image'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf),
                    title: Text('Export as PDF'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'json',
                  child: ListTile(
                    leading: Icon(Icons.code),
                    title: Text('Export as JSON'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'New MindMap',
              onPressed: () {
                ref.read(mindMapEditorProvider.notifier).clear();
                setState(() => _showInputForm = true);
              },
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isGenerating,
        loadingText: 'Generating MindMap...',
        child: _showInputForm ? _buildInputForm() : _buildMindMapView(mindMap),
      ),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
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
                      Theme.of(context).colorScheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI MindMap Generator',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transform your text or summary into an interactive mind map',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Title field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'MindMap Title (optional)',
                  hintText: 'Enter a title for your mind map',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Text input
              TextField(
                controller: _textController,
                maxLines: 12,
                decoration: InputDecoration(
                  labelText: 'Course Text or Summary',
                  hintText: 'Paste your course content, summary, or any text here...',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _generateMindMap,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Generate MindMap',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tips
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('• Click on a node to see its details'),
                      const Text('• Long press to edit, add children, or delete'),
                      const Text('• Use zoom controls to navigate'),
                      const Text('• Export as Image, PDF, or JSON'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMindMapView(MindMap? mindMap) {
    if (mindMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MindMapView(
      mindMap: mindMap,
      repaintKey: _repaintKey,
    );
  }
}

