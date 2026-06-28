import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _reset(BuildContext context) async {
    await GameScope.of(context).resetAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ローカルデータを初期化しました。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '設定',
      child: ListView(
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Ver1.0では未実装'),
              subtitle: Text(
                'AI書字判定、OpenAI API、Firebase、ログイン、課金、オンラインランキングは無効です。',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('ローカルデータを初期化'),
              subtitle: const Text('保存データと学習履歴を消去します。'),
              onTap: () => _reset(context),
            ),
          ),
        ],
      ),
    );
  }
}
