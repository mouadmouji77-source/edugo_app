import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/summary.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../services/local_database_service.dart';
import '../providers/summary_providers.dart';
import '../widgets/summary_content.dart';
import '../widgets/summary_actions.dart';

class SummaryScreen extends ConsumerWidget {
  final String summaryId;

  const SummaryScreen({
    super.key,
    required this.summaryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider(summaryId));
    final tr = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: summaryAsync.when(
          data: (summary) => Text(summary?.title ?? tr.summary),
          loading: () => Text(tr.loading),
          error: (_, __) => Text(tr.error),
        ),
        actions: [
          // Bouton de sauvegarde hors-ligne
          summaryAsync.when(
            data: (summary) => summary != null
                ? IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: tr.isFrench ? 'Sauvegarder hors-ligne' : 'Save offline',
                    onPressed: () => _saveOffline(context, ref, summary),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          summaryAsync.when(
            data: (summary) => summary != null
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(context, ref, summary, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: const Icon(Icons.share_outlined),
                          title: Text(tr.isFrench ? 'Partager' : 'Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export_pdf',
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf_outlined),
                          title: Text(tr.isFrench ? 'Exporter en PDF' : 'Export as PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'generate_quiz',
                        child: ListTile(
                          leading: const Icon(Icons.quiz_outlined),
                          title: Text(tr.isFrench ? 'Générer un Quiz' : 'Generate Quiz'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) {
          if (summary == null) {
            return const Center(
              child: Text('Summary not found'),
            );
          }
          
          return SingleChildScrollView(
            child: Column(
              children: [
                SummaryContent(summary: summary),
                const SizedBox(height: 16),
                SummaryActions(
                  summary: summary,
                  onGenerateQuiz: () => _generateQuiz(context, ref, summary),
                  onExportPdf: () => _exportPdf(context, ref, summary),
                  onShare: () => _shareSummary(context, summary),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const LoadingOverlay(
          isLoading: true,
          loadingText: 'Loading summary...',
          child: SizedBox.expand(),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(summaryProvider(summaryId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, Summary summary, String action) {
    switch (action) {
      case 'share':
        _shareSummary(context, summary);
        break;
      case 'export_pdf':
        _exportPdf(context, ref, summary);
        break;
      case 'generate_quiz':
        _generateQuiz(context, ref, summary);
        break;
    }
  }

  Future<void> _saveOffline(BuildContext context, WidgetRef ref, Summary summary) async {
    final tr = ref.read(translationsProvider);
    
    try {
      await LocalDatabaseService.saveSummary(
        title: summary.title,
        originalText: summary.originalText,
        summaryContent: summary.content,
        keywords: summary.keywords,
        language: null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(tr.isFrench 
                    ? 'Résumé sauvegardé hors-ligne !' 
                    : 'Summary saved offline!'),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: tr.isFrench ? 'Voir' : 'View',
              textColor: Colors.white,
              onPressed: () => context.push('/saved-summaries'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.isFrench 
                ? 'Erreur lors de la sauvegarde: $e' 
                : 'Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareSummary(BuildContext context, Summary summary) {
    final shareText = '${summary.title}\n\n${summary.content}';
    Share.share(shareText, subject: summary.title);
  }

  void _exportPdf(BuildContext context, WidgetRef ref, Summary summary) {
    ref.read(summaryControllerProvider).exportSummaryAsPdf(summary);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export started...')),
    );
  }

  void _generateQuiz(BuildContext context, WidgetRef ref, Summary summary) async {
    // Show dialog to select number of questions
    final numberOfQuestions = await showDialog<int>(
      context: context,
      builder: (context) => _QuizOptionsDialog(),
    );

    if (numberOfQuestions == null) return; // User cancelled

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Generating $numberOfQuestions questions...'),
            ],
          ),
        ),
      );

      final quizId = await ref.read(summaryControllerProvider).generateQuizFromSummary(
        summary,
        numberOfQuestions: numberOfQuestions,
      );
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        context.push('/quiz/$quizId');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _QuizOptionsDialog extends StatefulWidget {
  @override
  State<_QuizOptionsDialog> createState() => _QuizOptionsDialogState();
}

class _QuizOptionsDialogState extends State<_QuizOptionsDialog> {
  int _selectedQuestions = 5;
  final List<int> _options = [3, 5, 7, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiz Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many questions would you like?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((num) {
              final isSelected = _selectedQuestions == num;
              return ChoiceChip(
                label: Text('$num'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedQuestions = num);
                  }
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'More questions = longer generation time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedQuestions),
          child: Text('Generate $_selectedQuestions Questions'),
        ),
      ],
    );
  }
}
