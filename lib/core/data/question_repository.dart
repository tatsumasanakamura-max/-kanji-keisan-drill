import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/question_models.dart';
import '../models/progress_models.dart';

class QuestionRepository {
  QuestionRepository._();

  static final QuestionRepository instance = QuestionRepository._();

  List<KanjiReadingQuestion>? _kanjiReading;
  List<KanjiWritingPrompt>? _kanjiWriting;
  List<MathQuestion>? _mathQuestions;
  List<DailyChallenge>? _dailyChallenges;
  List<GachaReward>? _gachaRewards;
  List<EncyclopediaEntry>? _encyclopedia;

  Future<void> load() async {
    if (_kanjiReading != null) {
      return;
    }
    final String raw = await rootBundle.loadString('assets/data/sample_questions.json');
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    _kanjiReading = (json['kanji_reading'] as List<dynamic>)
        .map((dynamic value) => KanjiReadingQuestion.fromJson(value as Map<String, dynamic>))
        .toList();
    _kanjiWriting = (json['kanji_writing'] as List<dynamic>)
        .map((dynamic value) => KanjiWritingPrompt.fromJson(value as Map<String, dynamic>))
        .toList();
    _mathQuestions = (json['math_drill'] as List<dynamic>)
        .map((dynamic value) => MathQuestion.fromJson(value as Map<String, dynamic>))
        .toList();
    _dailyChallenges = (json['daily_challenges'] as List<dynamic>)
        .map((dynamic value) => DailyChallenge.fromJson(value as Map<String, dynamic>))
        .toList();
    _gachaRewards = (json['gacha_rewards'] as List<dynamic>)
        .map((dynamic value) => GachaReward.fromJson(value as Map<String, dynamic>))
        .toList();
    _encyclopedia = (json['encyclopedia'] as List<dynamic>)
        .map((dynamic value) => EncyclopediaEntry.fromJson(value as Map<String, dynamic>))
        .toList();
  }

  List<KanjiReadingQuestion> kanjiReading({int? grade}) {
    final items = _kanjiReading ?? <KanjiReadingQuestion>[];
    return grade == null ? items : items.where((q) => q.grade <= grade).toList();
  }

  List<KanjiWritingPrompt> kanjiWriting({int? grade}) {
    final items = _kanjiWriting ?? <KanjiWritingPrompt>[];
    return grade == null ? items : items.where((q) => q.grade <= grade).toList();
  }

  List<MathQuestion> mathQuestions({int? grade}) {
    final items = _mathQuestions ?? <MathQuestion>[];
    return grade == null ? items : items.where((q) => q.grade <= grade).toList();
  }

  List<DailyChallenge> dailyChallenges() => _dailyChallenges ?? <DailyChallenge>[];

  List<GachaReward> gachaRewards() => _gachaRewards ?? <GachaReward>[];

  List<EncyclopediaEntry> encyclopedia() => _encyclopedia ?? <EncyclopediaEntry>[];
}
