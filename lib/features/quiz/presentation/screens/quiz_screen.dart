import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/quiz.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../providers/quiz_providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({
    super.key,
    required this.quizId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<int> _selectedAnswers = [];
  bool _isSubmitting = false;

  void _selectAnswer(int answerIndex) {
    setState(() {
      if (_selectedAnswers.length <= _currentQuestionIndex) {
        _selectedAnswers.add(answerIndex);
      } else {
        _selectedAnswers[_currentQuestionIndex] = answerIndex;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
    });
  }

  void _previousQuestion() {
    setState(() {
      _currentQuestionIndex--;
    });
  }

  Future<void> _submitQuiz(Quiz quiz) async {
    setState(() => _isSubmitting = true);

    try {
      final score = await ref.read(quizControllerProvider).submitQuiz(
            quiz: quiz,
            selectedAnswers: _selectedAnswers,
          );
      
      if (mounted) {
        context.go('/quiz-result/${widget.quizId}?score=$score&total=${quiz.questions.length}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          quizAsync.when(
            data: (quiz) => quiz != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '${_currentQuestionIndex + 1}/${quiz.questions.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        loadingText: 'Submitting quiz...',
        child: quizAsync.when(
          data: (quiz) {
            if (quiz == null) {
              return const Center(child: Text('Quiz not found'));
            }

            // Initialize selected answers list
            if (_selectedAnswers.length < quiz.questions.length) {
              _selectedAnswers = List.filled(quiz.questions.length, -1);
            }

            final currentQuestion = quiz.questions[_currentQuestionIndex];
            final isLastQuestion = _currentQuestionIndex == quiz.questions.length - 1;
            final canProceed = _selectedAnswers[_currentQuestionIndex] != -1;

            return Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / quiz.questions.length,
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              currentQuestion.question,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Options
                        Expanded(
                          child: ListView.builder(
                            itemCount: currentQuestion.options.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : null,
                                  child: InkWell(
                                    onTap: () => _selectAnswer(index),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.outline,
                                                width: 2,
                                              ),
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              currentQuestion.options[index],
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Navigation buttons
                        Row(
                          children: [
                            if (_currentQuestionIndex > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _previousQuestion,
                                  child: const Text('Previous'),
                                ),
                              ),
                            if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: canProceed
                                    ? () {
                                        if (isLastQuestion) {
                                          _submitQuiz(quiz);
                                        } else {
                                          _nextQuestion();
                                        }
                                      }
                                    : null,
                                child: Text(isLastQuestion ? 'Submit Quiz' : 'Next'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading quiz: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(quizProvider(widget.quizId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
