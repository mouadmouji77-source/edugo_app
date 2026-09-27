import 'package:flutter/material.dart';
import '../../../../core/models/summary.dart';

class SummaryActions extends StatelessWidget {
  final Summary summary;
  final VoidCallback onGenerateQuiz;
  final VoidCallback onExportPdf;
  final VoidCallback onShare;

  const SummaryActions({
    super.key,
    required this.summary,
    required this.onGenerateQuiz,
    required this.onExportPdf,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          
          // Generate Quiz Button
          Card(
            child: ListTile(
              leading: Icon(
                Icons.quiz_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Generate Quiz'),
              subtitle: const Text('Test your knowledge with AI-generated questions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: onGenerateQuiz,
            ),
          ),
          const SizedBox(height: 8),
          
          // Export PDF Button
          Card(
            child: ListTile(
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('Export as PDF'),
              subtitle: const Text('Download a PDF version of this summary'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: onExportPdf,
            ),
          ),
          const SizedBox(height: 8),
          
          // Share Button
          Card(
            child: ListTile(
              leading: Icon(
                Icons.share_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: const Text('Share Summary'),
              subtitle: const Text('Share this summary with others'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}
