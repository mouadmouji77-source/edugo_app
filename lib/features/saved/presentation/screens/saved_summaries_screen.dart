import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../services/local_database_service.dart';

// Provider pour les résumés sauvegardés
final savedSummariesProvider = FutureProvider<List<SavedSummary>>((ref) async {
  return await LocalDatabaseService.getAllSummaries();
});

class SavedSummariesScreen extends ConsumerWidget {
  const SavedSummariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationsProvider);
    final savedSummariesAsync = ref.watch(savedSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.isFrench ? 'Résumés Sauvegardés' : 'Saved Summaries'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: tr.isFrench ? 'À propos du mode hors-ligne' : 'About offline mode',
            onPressed: () => _showOfflineInfo(context, tr),
          ),
        ],
      ),
      body: savedSummariesAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return _buildEmptyState(context, tr);
          }
          return _buildSummariesList(context, ref, summaries, tr);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(tr.errorOccurred),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(savedSummariesProvider),
                child: Text(tr.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppTranslations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr.isFrench ? 'Aucun résumé sauvegardé' : 'No saved summaries',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr.isFrench 
                  ? 'Sauvegardez vos résumés pour y accéder sans connexion internet.'
                  : 'Save your summaries to access them without internet connection.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(Icons.add),
              label: Text(tr.isFrench ? 'Créer un résumé' : 'Create a summary'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummariesList(
    BuildContext context, 
    WidgetRef ref, 
    List<SavedSummary> summaries,
    AppTranslations tr,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return _SummaryCard(
          summary: summary,
          tr: tr,
          onTap: () => _showSummaryDetail(context, ref, summary, tr),
          onDelete: () => _deleteSummary(context, ref, summary, tr),
          onToggleFavorite: () => _toggleFavorite(ref, summary),
        );
      },
    );
  }

  void _showSummaryDetail(
    BuildContext context, 
    WidgetRef ref, 
    SavedSummary summary,
    AppTranslations tr,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        summary.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: summary.isFavorite ? Colors.red : null,
                      ),
                      onPressed: () {
                        _toggleFavorite(ref, summary);
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Keywords
                      if (summary.keywords.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: summary.keywords.map((keyword) => Chip(
                            label: Text(keyword),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Summary content
                      SelectableText(
                        summary.summaryContent,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Metadata
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr.isFrench 
                                  ? 'Sauvegardé le ${_formatDate(summary.createdAt)}'
                                  : 'Saved on ${_formatDate(summary.createdAt)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _deleteSummary(
    BuildContext context, 
    WidgetRef ref, 
    SavedSummary summary,
    AppTranslations tr,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr.isFrench ? 'Supprimer le résumé ?' : 'Delete summary?'),
        content: Text(tr.isFrench 
            ? 'Cette action est irréversible.' 
            : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDatabaseService.deleteSummary(summary.id);
      ref.invalidate(savedSummariesProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.isFrench ? 'Résumé supprimé' : 'Summary deleted'),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(WidgetRef ref, SavedSummary summary) async {
    await LocalDatabaseService.toggleFavorite(summary.id);
    ref.invalidate(savedSummariesProvider);
  }

  void _showOfflineInfo(BuildContext context, AppTranslations tr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(tr.isFrench ? 'Mode Hors-ligne' : 'Offline Mode'),
          ],
        ),
        content: Text(
          tr.isFrench 
              ? 'Les résumés sauvegardés sont stockés localement sur votre appareil. '
                'Vous pouvez les consulter même sans connexion internet.\n\n'
                '• Les données sont conservées même après fermeture de l\'app\n'
                '• Aucune limite de stockage\n'
                '• Vos données restent privées sur votre appareil'
              : 'Saved summaries are stored locally on your device. '
                'You can view them even without internet connection.\n\n'
                '• Data is preserved even after closing the app\n'
                '• No storage limit\n'
                '• Your data stays private on your device',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr.close),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _SummaryCard extends StatelessWidget {
  final SavedSummary summary;
  final AppTranslations tr;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _SummaryCard({
    required this.summary,
    required this.tr,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(summary.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      summary.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: summary.isFavorite ? Colors.red : null,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.summaryContent,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (summary.keywords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: summary.keywords.take(3).map((keyword) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tr.isFrench ? 'Disponible hors-ligne' : 'Available offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

