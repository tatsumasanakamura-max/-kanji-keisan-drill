import 'package:flutter/material.dart';

import '../../core/state/game_controller.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class MathDrillScreen extends StatefulWidget {
  const MathDrillScreen({super.key});

  @override
  State<MathDrillScreen> createState() => _MathDrillScreenState();
}

class _MathDrillScreenState extends State<MathDrillScreen> {
  int _index = 0;
  int? _selected;
  QuizResult? _feedback;

  void _nextQuestion() {
    setState(() {
      _index += 1;
      _selected = null;
      _feedback = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final items = controller.mathQuestions;
    final question = items.isEmpty ? null : items[_index % items.length];

    return AppScaffold(
      title: '計算ドリル',
      child: question == null
          ? const Center(child: Text('問題が読み込まれていません。'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '問題 ${_index + 1} / ${items.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'ポイント ${controller.profile.points}   経験値 ${controller.profile.experience}   コンボ ${controller.profile.combo}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  question.expression,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(question.options.length, (optionIndex) {
                  final option = question.options[optionIndex];
                  final selected = _selected == optionIndex;
                  final answer = question.answer == option;
                  Color? color;
                  if (_feedback != null) {
                    if (selected && answer) {
                      color = Colors.green.shade100;
                    } else if (selected && !answer) {
                      color = Colors.red.shade100;
                    } else if (answer) {
                      color = Colors.green.shade50;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: color,
                      child: ListTile(
                        onTap: _feedback == null
                            ? () => setState(() => _selected = optionIndex)
                            : null,
                        title: Text('$option'),
                        trailing: answer && _feedback != null
                            ? const Icon(Icons.check_circle)
                            : null,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                if (_feedback != null) ...[
                  Text(
                    _feedback!.correct
                        ? '正解！ +${_feedback!.pointsEarned} pt、+${_feedback!.experienceEarned} 経験値、コンボ ${_feedback!.combo}'
                        : '不正解。正しい答え: ${_feedback!.correctAnswerLabel}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _feedback!.correct
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('解説: ${question.explanation}'),
                ] else
                  Text('解説: ${question.explanation}'),
                const Spacer(),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _selected = null;
                        _feedback = null;
                      }),
                      child: const Text('やり直す'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _feedback == null || question == null
                          ? (_selected == null
                              ? null
                              : () async {
                                  final result = await controller.answerMath(
                                      question, _selected!);
                                  setState(() {
                                    _feedback = result;
                                  });
                                })
                          : _nextQuestion,
                      child: Text(_feedback == null ? '答え合わせ' : '次へ'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
