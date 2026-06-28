import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final challenges = controller.dailyChallenges;

    return AppScaffold(
      title: '今日のチャレンジ',
      child: ListView.separated(
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          final progress = challenge.progress / challenge.target;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(challenge.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(challenge.description),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
                  const SizedBox(height: 8),
                  Text('${challenge.progress} / ${challenge.target}'),
                  Text(
                      '報酬: ${challenge.rewardPoints} pt / ${challenge.rewardExp} 経験値'),
                  if (challenge.cleared) ...[
                    const SizedBox(height: 8),
                    Text(
                      '達成',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
