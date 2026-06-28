import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/question_repository.dart';
import '../../core/models/question_models.dart';
import '../../core/state/game_controller.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class MathDrillScreen extends StatefulWidget {
  const MathDrillScreen({super.key});

  @override
  State<MathDrillScreen> createState() => _MathDrillScreenState();
}

class _MathDrillScreenState extends State<MathDrillScreen> {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Future<GradeQuestionSet>? _loadFuture;
  int? _loadedGrade;
  final List<int> _order = <int>[];
  int _cursor = 0;
  int? _lastQuestionIndex;
  QuizResult? _feedback;
  bool _answering = false;
  String? _localError;

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGradeData();
  }

  void _syncGradeData() {
    final controller = GameScope.of(context);
    final grade = controller.profile.selectedGrade;
    if (_loadedGrade == grade && _loadFuture != null) {
      return;
    }
    _loadedGrade = grade;
    _loadFuture = controller.loadGradeQuestions(grade);
    _cursor = 0;
    _lastQuestionIndex = null;
    _feedback = null;
    _answering = false;
    _localError = null;
    _answerController.clear();
    _order.clear();
  }

  void _buildOrder(int itemCount) {
    _order
      ..clear()
      ..addAll(List<int>.generate(itemCount, (index) => index));
    _order.shuffle(_random);
    if (_lastQuestionIndex != null &&
        itemCount > 1 &&
        _order.first == _lastQuestionIndex) {
      final swapIndex = 1 + _random.nextInt(itemCount - 1);
      final first = _order.first;
      _order[0] = _order[swapIndex];
      _order[swapIndex] = first;
    }
  }

  void _goToNextQuestion(int itemCount) {
    if (itemCount == 0) {
      return;
    }
    setState(() {
      _lastQuestionIndex = _order[_cursor];
      _cursor += 1;
      if (_cursor >= _order.length) {
        _buildOrder(itemCount);
        _cursor = 0;
      }
      _feedback = null;
      _answering = false;
      _localError = null;
      _answerController.clear();
    });
    _focusNode.requestFocus();
  }

  Future<void> _submitAnswer({
    required GameController controller,
    required MathQuestion question,
  }) async {
    if (_feedback != null || _answering) {
      return;
    }
    final responseText = _answerController.text.trim();
    if (responseText.isEmpty) {
      setState(() {
        _localError = '答えを入れてね。';
      });
      return;
    }

    setState(() {
      _answering = true;
      _localError = null;
    });

    try {
      final result = await controller.answerMath(question, responseText);
      if (!mounted) {
        return;
      }
      setState(() {
        _feedback = result;
        _answering = false;
      });
      _focusNode.unfocus();
    } on FormatException {
      if (!mounted) {
        return;
      }
      setState(() {
        _answering = false;
        _localError = '数字や分数を入れてね。';
      });
      _focusNode.requestFocus();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _answering = false;
        _localError = '読み込みに失敗しました。もう一度ためしてください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final gradeLabel =
        controller.gradeLabelFor(controller.profile.selectedGrade);

    return AppScaffold(
      title: '計算ドリル',
      child: FutureBuilder<GradeQuestionSet>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(
              message: _errorMessageFor(snapshot.error),
              onRetry: () {
                setState(() {
                  _loadedGrade = null;
                });
                _syncGradeData();
              },
              onGradeSelect: () => context.go('/grade'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final items = data.mathQuestions;
          if (items.isEmpty) {
            return _ErrorState(
              message: '${data.label} の計算問題がありません。別の学年を選ぶか、データを確認してください。',
              onRetry: () {
                setState(() {
                  _loadedGrade = null;
                });
                _syncGradeData();
              },
              onGradeSelect: () => context.go('/grade'),
            );
          }

          if (_order.isEmpty || _order.length != items.length) {
            _buildOrder(items.length);
          }
          if (_cursor >= _order.length) {
            _cursor = 0;
          }

          final question = items[_order[_cursor]];
          final answered = _feedback != null;

          return ListView(
            children: [
              _HeaderCard(
                gradeLabel: gradeLabel,
                questionNumber: _cursor + 1,
                totalCount: items.length,
                points: controller.profile.points,
                experience: controller.profile.experience,
                combo: controller.profile.combo,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '問題',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.expression,
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _ResultBanner(
                        text: answered
                            ? _feedback!.correct
                                ? '○ 正解！ +${_feedback!.pointsEarned} pt  +${_feedback!.experienceEarned} EXP  コンボ ${_feedback!.combo}'
                                : '× ざんねん！ 正解は ${_feedback!.correctAnswerLabel}'
                            : '答えを入力してね',
                        correct: _feedback?.correct,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _answerController,
                        focusNode: _focusNode,
                        enabled: !answered,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: answered
                            ? null
                            : (_) => _submitAnswer(
                                  controller: controller,
                                  question: question,
                                ),
                        style: Theme.of(context).textTheme.headlineSmall,
                        decoration: InputDecoration(
                          labelText: '答え',
                          hintText: '例: 12, 0.5, 3/4',
                          errorText: _localError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 62,
                        child: FilledButton.icon(
                          onPressed: answered || _answering
                              ? null
                              : () => _submitAnswer(
                                    controller: controller,
                                    question: question,
                                  ),
                          icon: const Icon(Icons.send),
                          label: const Text('送信'),
                        ),
                      ),
                      if (answered) ...[
                        const SizedBox(height: 16),
                        Text(
                          question.explanation,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (answered)
                SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: () => _goToNextQuestion(items.length),
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('次の問題へ'),
                  ),
                )
              else
                SizedBox(
                  height: 60,
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.touch_app),
                    label: const Text('答えを入れて送信すると判定します'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _errorMessageFor(Object? error) {
    if (error is QuestionRepositoryException) {
      return error.message;
    }
    return '問題データを読み込めませんでした。学年選択画面で別の学年を選ぶか、データを確認してください。';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.gradeLabel,
    required this.questionNumber,
    required this.totalCount,
    required this.points,
    required this.experience,
    required this.combo,
  });

  final String gradeLabel;
  final int questionNumber;
  final int totalCount;
  final int points;
  final int experience;
  final int combo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gradeLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '問題 $questionNumber / $totalCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MiniStat(label: 'ポイント', value: points.toString()),
                _MiniStat(label: '経験値', value: experience.toString()),
                _MiniStat(label: 'コンボ', value: combo.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.text,
    required this.correct,
  });

  final String text;
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final isCorrect = correct == true;
    final hasResult = correct != null;
    final backgroundColor = !hasResult
        ? Colors.amber.shade50
        : isCorrect
            ? Colors.green.shade100
            : Colors.red.shade100;
    final borderColor = !hasResult
        ? Colors.amber.shade300
        : isCorrect
            ? Colors.green.shade700
            : Colors.red.shade700;
    final icon = !hasResult
        ? Icons.touch_app
        : isCorrect
            ? Icons.check_circle
            : Icons.cancel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 3),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onGradeSelect,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onGradeSelect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 56, color: Colors.orange.shade700),
                const SizedBox(height: 12),
                Text(
                  '問題データを読み込めませんでした',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: onRetry,
                    child: const Text('もう一度読む'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: onGradeSelect,
                    child: const Text('学年選択へ'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
