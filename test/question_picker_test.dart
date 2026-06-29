import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_keisan_quest/core/models/question_models.dart';
import 'package:kanji_keisan_quest/core/services/question_picker.dart';

void main() {
  test('pick excludes answered questions while alternatives remain', () {
    final picker = QuestionPicker(random: Random(1));
    final questions = [
      _question('q1'),
      _question('q2'),
      _question('q3'),
    ];

    for (var i = 0; i < 10; i++) {
      final picked = picker.pick(
        questions: questions,
        history: const [],
        currentDifficulty: 1,
        excludedQuestionIds: {'q1', 'q2'},
      );
      expect(picked.id, 'q3');
    }
  });

  test('pick falls back when every question is already answered', () {
    final picker = QuestionPicker(random: Random(1));
    final questions = [
      _question('q1'),
      _question('q2'),
    ];

    final picked = picker.pick(
      questions: questions,
      history: const [],
      currentDifficulty: 1,
      excludedQuestionIds: {'q1', 'q2'},
    );

    expect({'q1', 'q2'}, contains(picked.id));
  });
}

DrillQuestion _question(String id) {
  return DrillQuestion(
    id: id,
    grade: 5,
    kanken: 6,
    difficulty: 1,
    type: QuestionType.reading,
    question: '精密な部品を作る。',
    choices: const ['せいみつ', 'せいまつ', 'しょうみつ', 'せいびつ'],
    answer: 0,
    meaning: '細かいところまで正確であること。',
    example: '精密な部品を作る。',
    tags: const ['reading'],
  );
}
