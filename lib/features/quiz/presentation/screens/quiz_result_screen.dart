import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_providers.dart';

class QuizResultScreen extends ConsumerWidget {
  final String quizId;
  final int score;
  final int total;

  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = total > 0 ? (score / total * 100).round() : 0;
    final quizAsync = ref.watch(quizProvider(quizId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Score Circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getScoreColor(percentage).withValues(alpha: 0.1),
                      border: Border.all(
                        color: _getScoreColor(percentage),
                        width: 4,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percentage%',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(percentage),
                              ),
                        ),
                        Text(
                          'Score',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: _getScoreColor(percentage),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Score Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Correct Answers:'),
                              Text(
                                '$score',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Questions:'),
                              Text(
                                '$total',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Percentage:'),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(percentage),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Performance message
                  Text(
                    _getPerformanceMessage(percentage),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(percentage),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Back to Dashboard'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    // Retake quiz
                    context.go('/quiz/$quizId');
                  },
                  child: const Text('Retake Quiz'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('View All Results'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceMessage(int percentage) {
    if (percentage >= 90) return 'Excellent! 🎉';
    if (percentage >= 80) return 'Great job! 👏';
    if (percentage >= 70) return 'Good work! 👍';
    if (percentage >= 60) return 'Not bad! 📚';
    return 'Keep studying! 💪';
  }
}
