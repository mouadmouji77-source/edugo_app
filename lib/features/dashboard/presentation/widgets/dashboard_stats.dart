import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../summary/presentation/providers/summary_providers.dart';
import '../../../quiz/presentation/providers/quiz_providers.dart';

class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(userSummariesProvider);
    final quizzesAsync = ref.watch(userQuizzesProvider);
    final scoresAsync = ref.watch(userScoresProvider);

    // Get values with fallbacks
    final summaryCount = summariesAsync.maybeWhen(
      data: (summaries) => summaries.length.toString(),
      orElse: () => '0',
    );
    
    final quizCount = quizzesAsync.maybeWhen(
      data: (quizzes) => quizzes.length.toString(),
      orElse: () => '0',
    );
    
    final avgScore = scoresAsync.maybeWhen(
      data: (scores) {
        if (scores.isEmpty) return 'N/A';
        final avg = scores.map((s) => s.percentage).reduce((a, b) => a + b) / scores.length;
        return '${avg.toStringAsFixed(0)}%';
      },
      orElse: () => 'N/A',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.summarize_outlined,
                title: 'Summaries',
                value: summaryCount,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.quiz_outlined,
                title: 'Quizzes',
                value: quizCount,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.score_outlined,
                title: 'Avg Score',
                value: avgScore,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
