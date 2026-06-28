import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/progress_models.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';
import '../shared/section_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final profile = controller.profile;
    final gradeLabel = profile.selectedGrade <= 6
        ? '小学 ${profile.selectedGrade} 年生'
        : '中学 ${profile.selectedGrade - 6} 年生';

    return AppScaffold(
      title: '漢字・計算クエスト Ver1.0',
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings),
        ),
      ],
      child: ListView(
        children: [
          _HeroCard(profile: profile, gradeLabel: gradeLabel),
          const SizedBox(height: 16),
          SectionCard(
            title: '学年選択',
            subtitle: '小学1年生から中学3年生までを選べます。',
            icon: Icons.school,
            onTap: () => context.push('/grade'),
          ),
          SectionCard(
            title: '漢字読み4択クイズ',
            subtitle: '4つの選択肢から読み方を答えます。',
            icon: Icons.quiz,
            onTap: () => context.push('/kanji-reading'),
          ),
          SectionCard(
            title: '漢字書き練習',
            subtitle: '指やタッチペンでお手本をなぞって練習します。',
            icon: Icons.edit,
            onTap: () => context.push('/kanji-writing'),
          ),
          SectionCard(
            title: '計算ドリル',
            subtitle: '学年に合った計算問題に挑戦します。',
            icon: Icons.calculate,
            onTap: () => context.push('/math-drill'),
          ),
          SectionCard(
            title: '今日のチャレンジ',
            subtitle: '今日の目標と報酬を確認します。',
            icon: Icons.today,
            onTap: () => context.push('/challenge'),
          ),
          SectionCard(
            title: 'ガチャ',
            subtitle: 'ポイントを使って報酬を手に入れます。',
            icon: Icons.card_giftcard,
            onTap: () => context.push('/gacha'),
          ),
          SectionCard(
            title: '図鑑',
            subtitle: '学んだ内容やヒントを見返します。',
            icon: Icons.menu_book,
            onTap: () => context.push('/encyclopedia'),
          ),
          SectionCard(
            title: '苦手リスト',
            subtitle: 'まちがえやすい問題を見返します。',
            icon: Icons.report,
            onTap: () => context.push('/weakness'),
          ),
          SectionCard(
            title: '成績',
            subtitle: 'ポイント、経験値、学習回数を確認します。',
            icon: Icons.insights,
            onTap: () => context.push('/results'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.gradeLabel,
  });

  final AppProfile profile;
  final String gradeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${profile.userName} さん',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('現在の学年: $gradeLabel'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(label: 'ポイント', value: profile.points.toString()),
                _MetricChip(label: '経験値', value: profile.experience.toString()),
                _MetricChip(label: 'レベル', value: profile.level.toString()),
                _MetricChip(label: 'コンボ', value: profile.combo.toString()),
                _MetricChip(label: '書き練習', value: profile.writingPracticeCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
