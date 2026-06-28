import 'package:flutter/material.dart';

import '../../core/data/question_repository.dart';
import '../shared/app_scaffold.dart';

class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rewards = QuestionRepository.instance.gachaRewards();
    return AppScaffold(
      title: 'ガチャ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ポイントを使って報酬を手に入れます。',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: rewards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.card_giftcard),
                    title: Text(reward.name),
                    subtitle: Text(
                        'レア度 ${_rarityLabel(reward.rarity)} ・ ${reward.description}'),
                    trailing: Text('${reward.pointsCost} pt'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _rarityLabel(String rarity) {
  switch (rarity) {
    case 'common':
      return 'ふつう';
    case 'rare':
      return 'レア';
    case 'superRare':
      return '激レア';
    default:
      return rarity;
  }
}
