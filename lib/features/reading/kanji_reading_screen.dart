import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/question_repository.dart';
import '../../core/models/question_models.dart';
import '../../core/state/game_controller.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class KanjiReadingScreen extends StatefulWidget {
  const KanjiReadingScreen({super.key});

  @override
  State<KanjiReadingScreen> createState() => _KanjiReadingScreenState();
}

class _KanjiReadingScreenState extends State<KanjiReadingScreen> {
  final Random _random = Random();
  Future<GradeQuestionSet>? _loadFuture;
  int? _loadedGrade;
  final List<int> _order = <int>[];
  int _cursor = 0;
  int? _lastQuestionIndex;
  int? _selectedIndex;
  QuizResult? _feedback;
  bool _answering = false;
  String? _localError;

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
    _selectedIndex = null;
    _feedback = null;
    _answering = false;
    _localError = null;
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
      _selectedIndex = null;
      _feedback = null;
      _answering = false;
      _localError = null;
    });
  }

  Future<void> _chooseAnswer({
    required GameController controller,
    required KanjiReadingQuestion question,
    required int selectedIndex,
  }) async {
    if (_feedback != null || _answering) {
      return;
    }
    setState(() {
      _selectedIndex = selectedIndex;
      _answering = true;
      _localError = null;
    });

    try {
      final result = await controller.answerReading(question, selectedIndex);
      if (!mounted) {
        return;
      }
      setState(() {
        _feedback = result;
        _answering = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIndex = null;
        _answering = false;
        _localError = '読み込みに失敗しました。もう一度ためしてください。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final gradeLabel = controller.gradeLabelFor(controller.profile.selectedGrade);

    return AppScaffold(
      title: '漢字読みクイズ',
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
          final items = data.kanjiReadingQuestions;
          if (items.isEmpty) {
            return _ErrorState(
              message:
                  '${data.label} の漢字読み問題がありません。別の学年を選ぶか、データを確認してください。',
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
          final correctIndex = question.answerIndex;
          final summaryText = answered
              ? _feedback!.correct
                  ? '○ 正解！ +${_feedback!.pointsEarned} pt  +${_feedback!.experienceEarned} EXP  コンボ ${_feedback!.combo}'
                  : '× ざんねん！ 正解は「${question.options[correctIndex]}」'
              : 'タップして答えてね';

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
              _QuestionCard(
                question: question,
                summaryText: summaryText,
                answered: answered,
                selectedIndex: _selectedIndex,
                correctIndex: correctIndex,
                feedback: _feedback,
                answering: _answering,
                onOptionTap: (index) => _chooseAnswer(
                  controller: controller,
                  question: question,
                  selectedIndex: index,
                ),
              ),
              const SizedBox(height: 16),
              if (_localError != null) ...[
                _InlineNotice(
                  message: _localError!,
                  icon: Icons.error_outline,
                  color: Colors.red.shade700,
                  backgroundColor: Colors.red.shade50,
                ),
                const SizedBox(height: 12),
              ],
              if (answered) ...[
                SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: () => _goToNextQuestion(items.length),
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('次の問題へ'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.touch_app),
                    label: const Text('答えを選ぶと判定します'),
                  ),
                ),
              ],
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.summaryText,
    required this.answered,
    required this.selectedIndex,
    required this.correctIndex,
    required this.feedback,
    required this.answering,
    required this.onOptionTap,
  });

  final KanjiReadingQuestion question;
  final String summaryText;
  final bool answered;
  final int? selectedIndex;
  final int correctIndex;
  final QuizResult? feedback;
  final bool answering;
  final ValueChanged<int> onOptionTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.kanji,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '意味: ${question.meaning}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ResultBanner(
              text: summaryText,
              correct: feedback?.correct,
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: answered || answering,
              child: Column(
                children: List.generate(question.options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      label: question.options[index],
                      index: index,
                      answered: answered,
                      selectedIndex: selectedIndex,
                      correctIndex: correctIndex,
                      onTap: () => onOptionTap(index),
                    ),
                  );
                }),
              ),
            ),
            if (answered) ...[
              const SizedBox(height: 8),
              Text(
                question.explanation,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.answered,
    required this.selectedIndex,
    required this.correctIndex,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool answered;
  final int? selectedIndex;
  final int correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final isCorrect = index == correctIndex;
    final isWrongSelection = answered && isSelected && !isCorrect;
    final showCorrect = answered && isCorrect;

    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFD1D5DB);
    String badge = '';
    Color badgeColor = Colors.transparent;

    if (answered) {
      if (isWrongSelection) {
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red.shade700;
        badge = '× ざんねん！';
        badgeColor = Colors.red.shade700;
      } else if (showCorrect) {
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green.shade700;
        badge = isSelected ? '○ 正解！' : '○ これが正解';
        badgeColor = Colors.green.shade700;
      }
    } else if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: answered ? 3 : 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: answered ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: answered ? borderColor : Colors.blueGrey.shade100,
                  foregroundColor: answered ? Colors.white : Colors.black87,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (badge.isNotEmpty)
                  Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
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

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.message,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
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
