import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class GradeSelectScreen extends StatelessWidget {
  const GradeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);

    return AppScaffold(
      title: 'コース選択',
      child: ListView(
        children: [
          Text('学年モード',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _CourseGrid(
            count: 6,
            labelBuilder: (value) => '小学$value年',
            selectedValue: controller.profile.useKankenMode
                ? null
                : controller.profile.selectedGrade,
            icon: Icons.school,
            onTap: controller.setGrade,
          ),
          const SizedBox(height: 24),
          Text('漢検モード',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _KankenGrid(
            selectedValue: controller.profile.useKankenMode
                ? controller.profile.selectedKanken
                : null,
            onTap: controller.setKanken,
          ),
        ],
      ),
    );
  }
}

class _CourseGrid extends StatelessWidget {
  const _CourseGrid({
    required this.count,
    required this.labelBuilder,
    required this.selectedValue,
    required this.icon,
    required this.onTap,
  });

  final int count;
  final String Function(int value) labelBuilder;
  final int? selectedValue;
  final IconData icon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final value = index + 1;
        return _CourseCard(
          label: labelBuilder(value),
          selected: value == selectedValue,
          icon: icon,
          onTap: () => onTap(value),
        );
      },
    );
  }
}

class _KankenGrid extends StatelessWidget {
  const _KankenGrid({
    required this.selectedValue,
    required this.onTap,
  });

  final int? selectedValue;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const levels = <int>[10, 9, 8, 7, 6, 5, 4, 3];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        return _CourseCard(
          label: '漢検$level級',
          selected: level == selectedValue,
          icon: Icons.workspace_premium,
          onTap: () => onTap(level),
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: colorScheme.primary),
              Text(label, style: Theme.of(context).textTheme.titleLarge),
              Text(selected ? '選択中' : 'タップで選択'),
            ],
          ),
        ),
      ),
    );
  }
}
