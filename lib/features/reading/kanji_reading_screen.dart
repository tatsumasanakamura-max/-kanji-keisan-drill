import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/question_repository.dart';
import '../../core/models/question_models.dart';
import '../../core/state/game_controller.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';
import '../shared/context_question_text.dart';

class KanjiReadingScreen extends StatefulWidget {
  const KanjiReadingScreen({super.key});

  @override
  State<KanjiReadingScreen> createState() => _KanjiReadingScreenState();
}

class _KanjiReadingScreenState extends State<KanjiReadingScreen> {
  Future<GradeQuestionSet>? _loadFuture;
  String? _loadedCourseKey;
  DrillQuestion? _question;
  int _questionNumber = 1;
  int? _selectedIndex;
  QuizResult? _feedback;
  bool _answering = false;
  DateTime _shownAt = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCourseData();
  }

  void _syncCourseData() {
    final controller = GameScope.of(context);
    final course = controller.selectedCourse;
    if (_loadedCourseKey == course.cacheKey && _loadFuture != null) {
      return;
    }
    _loadedCourseKey = course.cacheKey;
    _loadFuture = controller.loadSelectedCourseQuestions();
    _question = null;
    _questionNumber = 1;
    _selectedIndex = null;
    _feedback = null;
    _answering = false;
    _shownAt = DateTime.now();
  }

  void _ensureQuestion(GameController controller, List<DrillQuestion> items) {
    if (_question != null || items.isEmpty) {
      return;
    }
    _question = controller.pickQuestion(items);
    _shownAt = DateTime.now();
  }

  Future<void> _chooseAnswer({
    required GameController controller,
    required DrillQuestion question,
    required int selectedIndex,
  }) async {
    if (_feedback != null || _answering) {
      return;
    }
    setState(() {
      _selectedIndex = selectedIndex;
      _answering = true;
    });

    final result = await controller.answerDrill(
      question,
      selectedIndex,
      answerMillis: DateTime.now().difference(_shownAt).inMilliseconds,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _feedback = result;
      _answering = false;
    });
  }

  void _goToNextQuestion(GameController controller, List<DrillQuestion> items) {
    setState(() {
      _question = controller.pickQuestion(items);
      _questionNumber += 1;
      _selectedIndex = null;
      _feedback = null;
      _answering = false;
      _shownAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);

    return AppScaffold(
      title: '漢字ドリル',
      child: FutureBuilder<GradeQuestionSet>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(
              message: _errorMessageFor(snapshot.error),
              onRetry: () {
                setState(() => _loadedCourseKey = null);
                _syncCourseData();
              },
              onSelect: () => context.go('/grade'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final items = data.drillQuestions;
          if (items.isEmpty) {
            return _ErrorState(
              message: '${data.label} の問題がありません。',
              onRetry: () {
                setState(() => _loadedCourseKey = null);
                _syncCourseData();
              },
              onSelect: () => context.go('/grade'),
            );
          }

          _ensureQuestion(controller, items);
          final question = _question!;
          final answered = _feedback != null;

          return ListView(
            children: [
              _HeaderCard(
                courseLabel: controller.selectedCourseLabel,
                modeLabel: controller.studyMode.label,
                questionNumber: _questionNumber,
                totalCount: items.length,
                difficulty: controller.currentDifficulty,
                points: controller.profile.points,
                experience: controller.profile.experience,
                combo: controller.profile.combo,
              ),
              const SizedBox(height: 16),
              _QuestionCard(
                question: question,
                answered: answered,
                selectedIndex: _selectedIndex,
                feedback: _feedback,
                answering: _answering,
                onOptionTap: (index) => _chooseAnswer(
                  controller: controller,
                  question: question,
                  selectedIndex: index,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: FilledButton.icon(
                  onPressed: answered
                      ? () => _goToNextQuestion(controller, items)
                      : null,
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('次の問題へ'),
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
    return '問題データを読み込めませんでした。';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.courseLabel,
    required this.modeLabel,
    required this.questionNumber,
    required this.totalCount,
    required this.difficulty,
    required this.points,
    required this.experience,
    required this.combo,
  });

  final String courseLabel;
  final String modeLabel;
  final int questionNumber;
  final int totalCount;
  final int difficulty;
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
            Text(courseLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '$modeLabel  問題 $questionNumber / $totalCount  難易度 $difficulty'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
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
    required this.answered,
    required this.selectedIndex,
    required this.feedback,
    required this.answering,
    required this.onOptionTap,
  });

  final DrillQuestion question;
  final bool answered;
  final int? selectedIndex;
  final QuizResult? feedback;
  final bool answering;
  final ValueChanged<int> onOptionTap;

  @override
  Widget build(BuildContext context) {
    final summaryText = answered
        ? feedback!.correct
            ? '正解  +${feedback!.pointsEarned} pt  +${feedback!.experienceEarned} EXP'
            : '不正解  正解は「${feedback!.correctAnswerLabel}」'
        : '答えを選んでください';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeChip(type: question.type),
            const SizedBox(height: 12),
            ContextQuestionText(
              prompt: question.displayPrompt,
              sentence: question.displaySentence,
              target: question.target,
              reading: question.type == QuestionType.homophone
                  ? question.reading
                  : null,
            ),
            const SizedBox(height: 12),
            _ResultBanner(text: summaryText, correct: feedback?.correct),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: answered || answering,
              child: Column(
                children: List.generate(question.choices.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      label: question.choices[index],
                      index: index,
                      answered: answered,
                      selectedIndex: selectedIndex,
                      correctIndex: question.answer,
                      onTap: () => onOptionTap(index),
                    ),
                  );
                }),
              ),
            ),
            if (answered) ...[
              const SizedBox(height: 8),
              _Explanation(question: question),
            ],
          ],
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.question});

  final DrillQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('解説',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (question.meaning.isNotEmpty) Text('意味: ${question.meaning}'),
          if (question.example.isNotEmpty) Text('例文: ${question.example}'),
          if (question.mnemonic.isNotEmpty) Text('覚え方: ${question.mnemonic}'),
          if (question.synonyms.isNotEmpty)
            Text('類義語: ${question.synonyms.join('、')}'),
          if (question.antonyms.isNotEmpty)
            Text('対義語: ${question.antonyms.join('、')}'),
          Text('漢検: ${question.kanken}級 / 学年: ${question.grade}年'),
        ],
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
    final showWrong = answered && isSelected && !isCorrect;
    final showCorrect = answered && isCorrect;
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFD1D5DB);
    if (showWrong) {
      backgroundColor = Colors.red.shade100;
      borderColor = Colors.red.shade700;
    } else if (showCorrect) {
      backgroundColor = Colors.green.shade100;
      borderColor = Colors.green.shade700;
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade100;
      borderColor = Colors.blue.shade700;
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: isSelected ? 0.98 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: answered ? 3 : 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: answered ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        answered ? borderColor : colorScheme.primaryContainer,
                    foregroundColor: answered
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                    child: Text('${index + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (showCorrect)
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                  if (showWrong) Icon(Icons.cancel, color: Colors.red.shade700),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    return Chip(
        label: Text(_typeLabel(type)),
        avatar: const Icon(Icons.category, size: 18));
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.text, required this.correct});

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold, color: borderColor),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onSelect,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSelect;

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
                Text('問題データを読み込めませんでした',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('もう一度読み込む')),
                const SizedBox(height: 10),
                OutlinedButton(
                    onPressed: onSelect, child: const Text('コース選択へ')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _typeLabel(QuestionType type) {
  return switch (type) {
    QuestionType.reading => '読み',
    QuestionType.writing => '書き',
    QuestionType.compound => '熟語',
    QuestionType.sentence => '文中',
    QuestionType.homophone => '同音異義語',
    QuestionType.opposite => '対義語',
    QuestionType.synonym => '類義語',
    QuestionType.yojijukugo => '四字熟語',
    QuestionType.radical => '部首',
    QuestionType.correction => '誤字訂正',
  };
}
