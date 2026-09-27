import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/summary/presentation/providers/summary_providers.dart';
import '../../../../features/quiz/presentation/providers/quiz_providers.dart';
import '../../../../features/exam_generator/presentation/providers/exam_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Summaries', icon: Icon(Icons.summarize_outlined)),
            Tab(text: 'Quizzes', icon: Icon(Icons.quiz_outlined)),
            Tab(text: 'Scores', icon: Icon(Icons.score_outlined)),
            Tab(text: 'Exams', icon: Icon(Icons.assignment_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummariesTab(),
          _QuizzesTab(),
          _ScoresTab(),
          _ExamsTab(),
        ],
      ),
    );
  }
}

class _SummariesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(userSummariesProvider);

    return summariesAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.summarize_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No summaries yet'),
                Text('Create your first summary to get started'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            final summary = summaries[index];
            return Dismissible(
              key: Key(summary.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm"),
                      content: const Text("Are you sure you want to delete this summary?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                ref.read(summaryControllerProvider).deleteSummary(summary.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Summary deleted')),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: summary.pdfUrl != null
                        ? const Icon(Icons.picture_as_pdf)
                        : const Icon(Icons.description),
                  ),
                  title: Text(summary.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.content.length > 100
                            ? '${summary.content.substring(0, 100)}...'
                            : summary.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(summary.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => context.push('/summary/${summary.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text("Are you sure you want to delete this summary?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                          
                          if (confirm == true) {
                            ref.read(summaryControllerProvider).deleteSummary(summary.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Summary deleted')),
                            );
                          }
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading summaries: $error'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _QuizzesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(userQuizzesProvider);

    return quizzesAsync.when(
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No quizzes yet'),
                Text('Generate quizzes from your summaries'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return Dismissible(
              key: Key(quiz.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm"),
                      content: const Text("Are you sure you want to delete this quiz?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                ref.read(quizControllerProvider).deleteQuiz(quiz.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quiz deleted')),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.quiz),
                  ),
                  title: Text('Quiz ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${quiz.questions.length} questions'),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(quiz.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => context.push('/quiz/${quiz.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text("Are you sure you want to delete this quiz?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                          
                          if (confirm == true) {
                            ref.read(quizControllerProvider).deleteQuiz(quiz.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quiz deleted')),
                            );
                          }
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading quizzes: $error'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ScoresTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(userScoresProvider);

    return scoresAsync.when(
      data: (scores) {
        if (scores.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.score_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No quiz scores yet'),
                Text('Complete some quizzes to see your results'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            final percentage = score.percentage.round();
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getScoreColor(percentage).withValues(alpha: 0.1),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: _getScoreColor(percentage),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text('Quiz Result'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${score.score}/${score.totalQuestions} correct'),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(score.completedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: _getScoreColor(percentage),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading scores: $error'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ExamsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(userExamsProvider);

    return examsAsync.when(
      data: (exams) {
        if (exams.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No exams yet'),
                Text('Generate your first exam to get started'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            return Dismissible(
              key: Key(exam.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm"),
                      content: const Text("Are you sure you want to delete this exam?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                ref.read(examControllerProvider).deleteExam(exam.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exam deleted')),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: const Icon(Icons.assignment),
                  ),
                  title: Text(exam.examTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${exam.questions.length} questions • ${exam.schoolName}'),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(exam.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => context.push('/exam/${exam.id}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text("Are you sure you want to delete this exam?"),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("CANCEL"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                          
                          if (confirm == true) {
                            ref.read(examControllerProvider).deleteExam(exam.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Exam deleted')),
                            );
                          }
                        },
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading exams: $error'),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
