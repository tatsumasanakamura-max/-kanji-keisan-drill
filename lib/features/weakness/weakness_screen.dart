import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class WeaknessScreen extends StatelessWidget {
  const WeaknessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final items = [...controller.progressState.weakItems]
      ..sort((a, b) => b.mistakeCount.compareTo(a.mistakeCount));

    return AppScaffold(
      title: '苦手リスト',
      child: items.isEmpty
          ? const Center(child: Text('まだ学習履歴がありません。'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.isWeak
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: item.isWeak
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                    title: Text(item.label),
                    subtitle: Text(
                      '正答率 ${(item.correctRate * 100).round()}% / '
                      '不正解 ${item.mistakeCount}回 / '
                      '連続不正解 ${item.consecutiveWrong}回 / '
                      '連続正解 ${item.consecutiveCorrect}回 / '
                      '平均 ${(item.averageAnswerMillis / 1000).toStringAsFixed(1)}秒\n'
                      '最終出題日 ${_dateLabel(item.lastAnsweredAt)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}
