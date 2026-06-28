import 'package:flutter/material.dart';

import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

class GradeSelectScreen extends StatelessWidget {
  const GradeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final selected = controller.profile.selectedGrade;

    return AppScaffold(
      title: '学年選択',
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final grade = index + 1;
          final isSelected = grade == selected;
          return Card(
            child: InkWell(
              onTap: () => controller.setGrade(grade),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.school,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Text(
                      grade <= 6 ? '小学 $grade 年生' : '中学 ${grade - 6} 年生',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(isSelected ? '選択中' : 'タップで切り替え'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
