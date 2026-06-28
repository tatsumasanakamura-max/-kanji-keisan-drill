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
  final Map<String, GradeQuestionSet> _courseCache =
      <String, GradeQuestionSet>{};

  Future<void> load() async {
    if (_dailyChallenges != null) {
      return;
    }
    final json = await _loadJsonMap('assets/data/common_data.json');
    _dailyChallenges =
        _readList(json, 'daily_challenges', DailyChallenge.fromJson);
    _gachaRewards = _readList(json, 'gacha_rewards', GachaReward.fromJson);
    _encyclopedia = _readList(json, 'encyclopedia', EncyclopediaEntry.fromJson);
  }

  Future<GradeQuestionSet> loadGrade(int grade) {
    return loadCourse(StudyCourse.grade(grade));
  }

  Future<GradeQuestionSet> loadKanken(int level) {
    return loadCourse(StudyCourse.kanken(level));
  }

  Future<GradeQuestionSet> loadCourse(StudyCourse course) async {
    final cached = _courseCache[course.cacheKey];
    if (cached != null) {
      return cached;
    }

    final json = await _loadJsonMap(course.assetPath);
    final set = GradeQuestionSet.fromJson(json);
    _validateQuestionSet(set, course);
    _courseCache[course.cacheKey] = set;
    return set;
  }

  List<DailyChallenge> dailyChallenges() =>
      _dailyChallenges ?? <DailyChallenge>[];

  List<GachaReward> gachaRewards() => _gachaRewards ?? <GachaReward>[];

  List<EncyclopediaEntry> encyclopedia() =>
      _encyclopedia ?? <EncyclopediaEntry>[];

  Future<Map<String, dynamic>> _loadJsonMap(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw QuestionRepositoryException('データ形式が正しくありません: $assetPath');
      }
      return decoded;
    } on FlutterError catch (error) {
      throw QuestionRepositoryException(
          'データを読み込めませんでした: $assetPath\n${error.message}');
    } on FormatException catch (error) {
      throw QuestionRepositoryException(
          'JSONの読み込みに失敗しました: $assetPath\n${error.message}');
    }
  }

  List<T> _readList<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawList = json[key];
    if (rawList is! List<dynamic>) {
      throw QuestionRepositoryException('必要なデータが見つかりません: $key');
    }
    return rawList
        .map((dynamic value) => fromJson(value as Map<String, dynamic>))
        .toList();
  }

  void _validateQuestionSet(GradeQuestionSet set, StudyCourse course) {
    if (set.label.trim().isEmpty) {
      throw QuestionRepositoryException('コース名が空です: ${course.assetPath}');
    }
    if (set.drillQuestions.isEmpty && set.mathQuestions.isEmpty) {
      throw QuestionRepositoryException('問題が空です: ${course.assetPath}');
    }
    for (final question in set.drillQuestions) {
      if (question.difficulty < 1 || question.difficulty > 5) {
        throw QuestionRepositoryException('難易度は1から5で指定してください: ${question.id}');
      }
      if (question.choices.length < 2) {
        throw QuestionRepositoryException('選択肢が不足しています: ${question.id}');
      }
    }
  }
}
