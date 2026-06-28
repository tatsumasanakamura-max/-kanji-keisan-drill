import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/progress_models.dart';
import '../models/question_models.dart';

class QuestionRepositoryException implements Exception {
  QuestionRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuestionRepository {
  QuestionRepository._();

  static final QuestionRepository instance = QuestionRepository._();

  List<DailyChallenge>? _dailyChallenges;
  List<GachaReward>? _gachaRewards;
  List<EncyclopediaEntry>? _encyclopedia;
  final Map<int, GradeQuestionSet> _gradeCache = <int, GradeQuestionSet>{};

  Future<void> load() async {
    if (_dailyChallenges != null) {
      return;
    }
    final Map<String, dynamic> json = await _loadJsonMap('assets/data/common_data.json');
    _dailyChallenges = _readList(json, 'daily_challenges', DailyChallenge.fromJson);
    _gachaRewards = _readList(json, 'gacha_rewards', GachaReward.fromJson);
    _encyclopedia = _readList(json, 'encyclopedia', EncyclopediaEntry.fromJson);
  }

  Future<GradeQuestionSet> loadGrade(int grade) async {
    final cached = _gradeCache[grade];
    if (cached != null) {
      return cached;
    }

    final Map<String, dynamic> json =
        await _loadJsonMap('assets/data/grades/grade_$grade.json');
    final set = GradeQuestionSet.fromJson(json);
    _validateGradeSet(set);
    _gradeCache[grade] = set;
    return set;
  }

  List<DailyChallenge> dailyChallenges() => _dailyChallenges ?? <DailyChallenge>[];

  List<GachaReward> gachaRewards() => _gachaRewards ?? <GachaReward>[];

  List<EncyclopediaEntry> encyclopedia() => _encyclopedia ?? <EncyclopediaEntry>[];

  Future<Map<String, dynamic>> _loadJsonMap(String assetPath) async {
    try {
      final String raw = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw QuestionRepositoryException(
          'データ形式が正しくありません: $assetPath',
        );
      }
      return decoded;
    } on FlutterError catch (error) {
      throw QuestionRepositoryException('データを読み込めませんでした: $assetPath\n${error.message}');
    } on FormatException catch (error) {
      throw QuestionRepositoryException('JSONの読み込みに失敗しました: $assetPath\n${error.message}');
    }
  }

  List<T> _readList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawList = json[key];
    if (rawList is! List<dynamic>) {
      throw QuestionRepositoryException('必須データが見つかりません: $key');
    }
    return rawList
        .map((dynamic value) => fromJson(value as Map<String, dynamic>))
        .toList();
  }

  void _validateGradeSet(GradeQuestionSet set) {
    if (set.grade < 1 || set.grade > 9) {
      throw QuestionRepositoryException('学年データの値が不正です: ${set.grade}');
    }
    if (set.label.trim().isEmpty) {
      throw QuestionRepositoryException('学年ラベルが空です: grade_${set.grade}');
    }
    if (set.kanjiReadingQuestions.isEmpty &&
        set.kanjiWritingPrompts.isEmpty &&
        set.mathQuestions.isEmpty) {
      throw QuestionRepositoryException('問題が空です: grade_${set.grade}');
    }
  }
}
