import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class WeaknessScreen extends StatelessWidget {
  const WeaknessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final items = controller.progressState.weakItems;

    return AppScaffold(
      title: '苦手リスト',
      child: items.isEmpty
          ? const Center(child: Text('まだ苦手な問題はありません。'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(item.label),
                      subtitle: Text('まちがい回数 ${item.mistakeCount} 回'),
                    ),
                  );
                },
            ),
    );
  }
}
