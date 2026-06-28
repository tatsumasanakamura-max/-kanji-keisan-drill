import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/progress_models.dart';
import '../../core/models/question_models.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';
import '../shared/section_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final profile = controller.profile;

    return AppScaffold(
      title: '漢字・計算ドリル Ver2.0',
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings),
          tooltip: '設定',
        ),
      ],
      child: ListView(
        children: [
          _HeroCard(
              profile: profile, courseLabel: controller.selectedCourseLabel),
          const SizedBox(height: 16),
          SectionCard(
            title: '学年モード / 漢検モード',
            subtitle: '小学1〜6年、漢検10〜3級から選択',
            icon: Icons.school,
            onTap: () => context.push('/grade'),
          ),
          const SizedBox(height: 8),
          Text('学習モード',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _StudyModeGrid(
            selected: controller.studyMode,
            onSelected: (mode) {
              controller.setStudyMode(mode);
              context.push('/kanji-reading');
            },
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '漢字ドリル',
            subtitle: '10カテゴリの問題を出題アルゴリズムで学習',
            icon: Icons.quiz,
            onTap: () => context.push('/kanji-reading'),
          ),
          SectionCard(
            title: '書き練習',
            subtitle: '手書きキャンバスで漢字を書く練習',
            icon: Icons.edit,
            onTap: () => context.push('/kanji-writing'),
          ),
          SectionCard(
            title: '計算ドリル',
            subtitle: '選択学年の計算問題に挑戦',
            icon: Icons.calculate,
            onTap: () => context.push('/math-drill'),
          ),
          SectionCard(
            title: '今日のチャレンジ',
            subtitle: 'デイリーボーナスと学習目標',
            icon: Icons.today,
            onTap: () => context.push('/challenge'),
          ),
          SectionCard(
            title: '苦手リスト',
            subtitle: '正答率、回答時間、最終出題日を確認',
            icon: Icons.report,
            onTap: () => context.push('/weakness'),
          ),
          SectionCard(
            title: '成績',
            subtitle: 'カテゴリ別、学年別、漢検級別の成績',
            icon: Icons.insights,
            onTap: () => context.push('/results'),
          ),
          SectionCard(
            title: 'コレクション',
            subtitle: 'ポイントで報酬を集める',
            icon: Icons.card_giftcard,
            onTap: () => context.push('/gacha'),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.courseLabel,
  });

  final AppProfile profile;
  final String courseLabel;

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
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${profile.userName}さん',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('現在のコース: $courseLabel'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(label: 'ポイント', value: profile.points.toString()),
                _MetricChip(label: '経験値', value: profile.experience.toString()),
                _MetricChip(label: 'レベル', value: profile.level.toString()),
                _MetricChip(label: 'コンボ', value: profile.combo.toString()),
                _MetricChip(
                    label: '連続学習', value: '${profile.studyStreakDays}日'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyModeGrid extends StatelessWidget {
  const _StudyModeGrid({
    required this.selected,
    required this.onSelected,
  });

  final StudyMode selected;
  final ValueChanged<StudyMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StudyMode.values.map((mode) {
        return ChoiceChip(
          label: Text(mode.label),
          selected: selected == mode,
          onSelected: (_) => onSelected(mode),
        );
      }).toList(),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
