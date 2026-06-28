import 'dart:math';

import '../models/progress_models.dart';
import '../models/question_models.dart';

class QuestionPicker {
  QuestionPicker({Random? random}) : _random = random ?? Random();

  final Random _random;

  DrillQuestion pick({
    required List<DrillQuestion> questions,
    required List<WeakItem> history,
    required int currentDifficulty,
    StudyMode mode = StudyMode.normal,
  }) {
    if (questions.isEmpty) {
      throw StateError('question list is empty');
    }

    final candidates = questions
        .where(
            (question) => (question.difficulty - currentDifficulty).abs() <= 1)
        .toList();
    final pool = candidates.isEmpty ? questions : candidates;
    final historyById = {for (final item in history) item.questionId: item};

    if (mode == StudyMode.weakness) {
      return _pickWeak(pool, historyById) ?? _pickAny(pool);
    }
    if (mode == StudyMode.reviewToday) {
      return _pickReview(pool, historyById) ??
          _pickWeak(pool, historyById) ??
          _pickAny(pool);
    }

    final roll = _random.nextInt(100);
    if (roll < 40) {
      return _pickNew(pool, historyById) ?? _pickAny(pool);
    }
    if (roll < 80) {
      return _pickWeak(pool, historyById) ??
          _pickNew(pool, historyById) ??
          _pickAny(pool);
    }
    return _pickReview(pool, historyById) ??
        _pickWeak(pool, historyById) ??
        _pickAny(pool);
  }

  DrillQuestion _pickAny(List<DrillQuestion> questions) {
    return questions[_random.nextInt(questions.length)];
  }

  DrillQuestion? _pickNew(
    List<DrillQuestion> questions,
    Map<String, WeakItem> historyById,
  ) {
    final items = questions
        .where((question) => !historyById.containsKey(question.id))
        .toList();
    if (items.isEmpty) {
      return null;
    }
    return _pickAny(items);
  }

  DrillQuestion? _pickWeak(
    List<DrillQuestion> questions,
    Map<String, WeakItem> historyById,
  ) {
    final items = questions
        .where((question) => historyById[question.id]?.isWeak ?? false)
        .toList()
      ..sort((a, b) {
        final left = historyById[a.id]!;
        final right = historyById[b.id]!;
        return right.mistakeCount.compareTo(left.mistakeCount);
      });
    if (items.isEmpty) {
      return null;
    }
    return items[_random.nextInt(items.length.clamp(1, 6))];
  }

  DrillQuestion? _pickReview(
    List<DrillQuestion> questions,
    Map<String, WeakItem> historyById,
  ) {
    final today = DateTime.now();
    final reviewIntervals = <int>[1, 3, 7, 14];
    final due = <DrillQuestion>[];
    for (final question in questions) {
      final lastAnsweredAt = historyById[question.id]?.lastAnsweredAt;
      if (lastAnsweredAt == null) {
        continue;
      }
      final days = DateTime(today.year, today.month, today.day)
          .difference(DateTime(
              lastAnsweredAt.year, lastAnsweredAt.month, lastAnsweredAt.day))
          .inDays;
      if (reviewIntervals.contains(days) || days > 14) {
        due.add(question);
      }
    }
    if (due.isEmpty) {
      return null;
    }
    return _pickAny(due);
  }
}
