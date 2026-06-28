import 'package:flutter/material.dart';

import '../../core/models/progress_models.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final profile = controller.profile;
    final results = controller.progressState.results;
    final weakItems = controller.progressState.weakItems
        .where((item) => item.isWeak)
        .toList()
      ..sort((a, b) => b.mistakeCount.compareTo(a.mistakeCount));
    final correctRate = profile.totalSolved == 0
        ? 0
        : (profile.correctCount / profile.totalSolved * 100).round();
    final avgMillis = _averageAnswerMillis(results);

    return AppScaffold(
      title: '成績',
      child: ListView(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatsCard(title: '総問題数', value: '${profile.totalSolved}'),
              _StatsCard(title: '総正答率', value: '$correctRate%'),
              _StatsCard(
                  title: '平均回答時間',
                  value: avgMillis == 0
                      ? '-'
                      : '${(avgMillis / 1000).toStringAsFixed(1)}秒'),
              _StatsCard(title: '連続学習日数', value: '${profile.studyStreakDays}日'),
              _StatsCard(title: '獲得経験値', value: '${profile.experience}'),
              _StatsCard(title: 'レベル', value: '${profile.level}'),
              _StatsCard(title: '最高コンボ', value: '${profile.bestCombo}'),
            ],
          ),
          const SizedBox(height: 20),
          _RateSection(
              title: 'カテゴリ別正答率',
              rates: _ratesBy(results, (result) => result.category)),
          _RateSection(
              title: '学年別正答率',
              rates: _ratesBy(results.where((r) => r.grade > 0),
                  (result) => '${result.grade}年')),
          _RateSection(
              title: '漢検級別正答率',
              rates: _ratesBy(results.where((r) => r.kanken > 0),
                  (result) => '${result.kanken}級')),
          const SizedBox(height: 12),
          Text('苦手ランキング',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (weakItems.isEmpty)
            const Text('苦手問題はまだありません。')
          else
            ...weakItems.take(5).map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.trending_down),
                      title: Text(item.label),
                      subtitle: Text(
                          '正答率 ${(item.correctRate * 100).round()}% / 不正解 ${item.mistakeCount}回 / 平均 ${(item.averageAnswerMillis / 1000).toStringAsFixed(1)}秒'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _RateSection extends StatelessWidget {
  const _RateSection({required this.title, required this.rates});

  final String title;
  final Map<String, int> rates;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (rates.isEmpty)
            const Text('データがありません。')
          else
            ...rates.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 96, child: Text(entry.key)),
                    Expanded(
                        child:
                            LinearProgressIndicator(value: entry.value / 100)),
                    const SizedBox(width: 12),
                    SizedBox(width: 44, child: Text('${entry.value}%')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

Map<String, int> _ratesBy(
  Iterable<ResultSummary> results,
  String Function(ResultSummary result) keyOf,
) {
  final totals = <String, int>{};
  final corrects = <String, int>{};
  for (final result in results) {
    final key = keyOf(result);
    totals[key] = (totals[key] ?? 0) + result.totalCount;
    corrects[key] = (corrects[key] ?? 0) + result.correctCount;
  }
  return {
    for (final entry in totals.entries)
      entry.key: ((corrects[entry.key] ?? 0) / entry.value * 100).round(),
  };
}

int _averageAnswerMillis(List<ResultSummary> results) {
  final answered = results.where((result) => result.answerMillis > 0).toList();
  if (answered.isEmpty) {
    return 0;
  }
  return answered
          .map((result) => result.answerMillis)
          .reduce((a, b) => a + b) ~/
      answered.length;
}
