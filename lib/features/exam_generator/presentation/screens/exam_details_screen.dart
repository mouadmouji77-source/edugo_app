import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/exam_providers.dart';
import '../widgets/exam_preview.dart';

class ExamDetailsScreen extends ConsumerWidget {
  final String examId;

  const ExamDetailsScreen({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examAsync = ref.watch(examProvider(examId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Details'),
      ),
      body: examAsync.when(
        data: (exam) {
          if (exam == null) {
            return const Center(
              child: Text('Exam not found'),
            );
          }
          return ExamPreview(
            exam: exam,
            onBack: () => context.pop(),
          );
        },
        loading: () => const LoadingOverlay(
          isLoading: true,
          loadingText: 'Loading exam...',
          child: SizedBox.expand(),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
