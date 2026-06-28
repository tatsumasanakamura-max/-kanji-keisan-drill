import 'package:flutter/material.dart';

import '../../core/data/question_repository.dart';
import '../shared/app_scaffold.dart';

class EncyclopediaScreen extends StatelessWidget {
  const EncyclopediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = QuestionRepository.instance.encyclopedia();
    return AppScaffold(
      title: '図鑑',
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ExpansionTile(
              title: Text(item.title),
              subtitle: Text(item.category == 'system' ? 'システム' : item.category),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(item.body),
              ],
            ),
          );
        },
      ),
    );
  }
}
