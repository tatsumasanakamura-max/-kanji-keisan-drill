import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final profile = controller.profile;
    final recent = controller.progressState.results;
    final correctRate = profile.totalSolved == 0
        ? 0
        : (profile.correctCount / profile.totalSolved * 100).round();

    return AppScaffold(
      title: '成績',
      child: ListView(
        children: [
          _StatsCard(title: 'ポイント', value: '${profile.points}'),
          _StatsCard(title: '経験値', value: '${profile.experience}'),
          _StatsCard(title: 'レベル', value: '${profile.level}'),
          _StatsCard(title: '学習回数', value: '${profile.totalSolved}'),
          _StatsCard(title: '書き練習', value: '${profile.writingPracticeCount}'),
          _StatsCard(title: '正答率', value: '$correctRate%'),
          const SizedBox(height: 8),
          Text('最近の結果', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Text('まだ学習結果はありません。')
          else
            ...recent.take(10).map(
                  (result) => Card(
                    child: ListTile(
                      title: Text(_subjectLabel(result.subject)),
                      subtitle: Text(
                        '${result.correctCount == 1 ? "正解" : "不正解"}  '
                        'pt +${result.pointsEarned}  経験値 +${result.experienceEarned}  コンボ ${result.comboMax}',
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

String _subjectLabel(String subject) {
  switch (subject) {
    case 'kanji_reading':
      return '漢字読み';
    case 'kanji_writing':
      return '漢字書き練習';
    case 'math_drill':
      return '計算ドリル';
    default:
      return subject;
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
