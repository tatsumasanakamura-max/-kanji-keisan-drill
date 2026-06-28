import 'package:flutter/foundation.dart';

import '../data/question_repository.dart';
import '../models/progress_models.dart';
import '../models/question_models.dart';
import '../storage/app_storage.dart';

class QuizResult {
  QuizResult({
    required this.correct,
    required this.message,
    required this.pointsEarned,
    required this.experienceEarned,
    required this.combo,
    required this.correctAnswerLabel,
  });

  final bool correct;
  final String message;
  final int pointsEarned;
  final int experienceEarned;
  final int combo;
  final String correctAnswerLabel;
}

class GameController extends ChangeNotifier {
  GameController._();

  static final GameController instance = GameController._();

  AppProfile _profile = AppProfile.defaultProfile();
  ProgressState _progressState = ProgressState.defaultState();
  bool _initialized = false;

  AppProfile get profile => _profile;
  ProgressState get progressState => _progressState;
  bool get isInitialized => _initialized;

  Future<GradeQuestionSet> loadGradeQuestions(int grade) {
    return QuestionRepository.instance.loadGrade(grade);
  }

  String gradeLabelFor(int grade) {
    if (grade <= 6) {
      return '小学 $grade 年生';
    }
    return '中学 ${grade - 6} 年生';
  }

  String get selectedGradeLabel => gradeLabelFor(_profile.selectedGrade);

  List<DailyChallenge> get dailyChallenges {
    if (_progressState.dailyChallenges.isNotEmpty) {
      return _progressState.dailyChallenges;
    }
    return QuestionRepository.instance
        .dailyChallenges()
        .map((challenge) => DailyChallenge.fromJson(challenge.toJson()))
        .toList();
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await QuestionRepository.instance.load();
    _profile = await AppStorage.instance.loadProfile();
    _progressState = await AppStorage.instance.loadProgressState();
    if (_progressState.dailyChallenges.isEmpty) {
      _progressState = ProgressState(
        weakItems: _progressState.weakItems,
        ownedRewards: _progressState.ownedRewards,
        dailyChallenges: QuestionRepository.instance
            .dailyChallenges()
            .map((challenge) => DailyChallenge.fromJson(challenge.toJson()))
            .toList(),
        results: _progressState.results,
      );
      await AppStorage.instance.saveProgressState(_progressState);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> resetAll() async {
    await AppStorage.instance.resetAll();
    _profile = AppProfile.defaultProfile();
    _progressState = ProgressState(
      weakItems: <WeakItem>[],
      ownedRewards: <GachaReward>[],
      dailyChallenges: QuestionRepository.instance
          .dailyChallenges()
          .map((challenge) => DailyChallenge.fromJson(challenge.toJson()))
          .toList(),
      results: <ResultSummary>[],
    );
    await _persist();
  }

  Future<void> setGrade(int grade) async {
    _profile = _profile.copyWith(selectedGrade: grade);
    await _persistProfile();
  }

  Future<QuizResult> answerReading(
      KanjiReadingQuestion question, int selectedIndex) {
    final correct = selectedIndex == question.answerIndex;
    return _applyAnswer(
      subject: 'kanji_reading',
      questionId: question.id,
      label: '${question.kanji} (${question.reading})',
      correct: correct,
      correctAnswerLabel: question.options[question.answerIndex],
    );
  }

  Future<QuizResult> answerMath(MathQuestion question, String responseText) {
    final parsedAnswer = _parseMathAnswer(responseText);
    if (parsedAnswer == null) {
      throw FormatException('invalid math answer');
    }
    final correct = _numbersMatch(parsedAnswer, question.answer);
    return _applyAnswer(
      subject: 'math_drill',
      questionId: question.id,
      label: question.expression,
      correct: correct,
      correctAnswerLabel: question.answer.toString(),
    );
  }

  Future<QuizResult> completeWritingPractice(KanjiWritingPrompt prompt) {
    return _applySuccess(
      subject: 'kanji_writing',
      rewardPoints: 15,
      rewardExperience: 15,
      dailyTags: <String>[...prompt.tags, 'writing'],
      correctAnswerLabel: 'できた',
    );
  }

  Future<QuizResult> _applyAnswer({
    required String subject,
    required String questionId,
    required String label,
    required bool correct,
    required String correctAnswerLabel,
  }) async {
    int pointsEarned = 0;
    int experienceEarned = 0;
    int comboForResult = 0;

    if (correct) {
      comboForResult = _profile.combo + 1;
      final comboBonus = comboForResult > 1 ? comboForResult - 1 : 0;
      pointsEarned = 10 + comboBonus * 2;
      experienceEarned = 15 + comboBonus * 3;
      _profile = _profile.copyWith(
        points: _profile.points + pointsEarned,
        experience: _profile.experience + experienceEarned,
        combo: comboForResult,
        bestCombo: comboForResult > _profile.bestCombo
            ? comboForResult
            : _profile.bestCombo,
        totalSolved: _profile.totalSolved + 1,
        correctCount: _profile.correctCount + 1,
        currentStreak: _profile.currentStreak + 1,
        lastPlayedAt: DateTime.now(),
      );
      _profile = _applyLevelUp(_profile);
      _incrementDailyProgress(const <String>['mixed', 'reading_math']);
    } else {
      _profile = _profile.copyWith(
        combo: 0,
        totalSolved: _profile.totalSolved + 1,
        currentStreak: 0,
        lastPlayedAt: DateTime.now(),
      );
      _upsertWeakItem(subject: subject, questionId: questionId, label: label);
    }

    _appendResult(
      subject: subject,
      correct: correct,
      pointsEarned: pointsEarned,
      experienceEarned: experienceEarned,
      comboMax: comboForResult,
    );
    await _persist();

    return QuizResult(
      correct: correct,
      message: correct ? '正解です！' : 'また挑戦してね。',
      pointsEarned: pointsEarned,
      experienceEarned: experienceEarned,
      combo: _profile.combo,
      correctAnswerLabel: correctAnswerLabel,
    );
  }

  Future<QuizResult> _applySuccess({
    required String subject,
    required int rewardPoints,
    required int rewardExperience,
    required List<String> dailyTags,
    required String correctAnswerLabel,
  }) async {
    final comboForResult = _profile.combo + 1;
    _profile = _profile.copyWith(
      points: _profile.points + rewardPoints,
      experience: _profile.experience + rewardExperience,
      combo: comboForResult,
      bestCombo: comboForResult > _profile.bestCombo
          ? comboForResult
          : _profile.bestCombo,
      totalSolved: _profile.totalSolved + 1,
      correctCount: _profile.correctCount + 1,
      writingPracticeCount: _profile.writingPracticeCount + 1,
      currentStreak: _profile.currentStreak + 1,
      lastPlayedAt: DateTime.now(),
    );
    _profile = _applyLevelUp(_profile);
    _incrementDailyProgress(dailyTags);
    _appendResult(
      subject: subject,
      correct: true,
      pointsEarned: rewardPoints,
      experienceEarned: rewardExperience,
      comboMax: comboForResult,
    );
    await _persist();

    return QuizResult(
      correct: true,
      message: 'よくできました！',
      pointsEarned: rewardPoints,
      experienceEarned: rewardExperience,
      combo: _profile.combo,
      correctAnswerLabel: correctAnswerLabel,
    );
  }

  void _incrementDailyProgress(List<String> matchedTags) {
    final updated = <DailyChallenge>[];
    for (final challenge in dailyChallenges) {
      final shouldCount = challenge.tags.any(matchedTags.contains) ||
          challenge.tags.contains('mixed') ||
          challenge.tags.contains('reading_math');
      if (shouldCount) {
        final progress = challenge.progress + 1;
        updated.add(
          DailyChallenge(
            id: challenge.id,
            title: challenge.title,
            description: challenge.description,
            target: challenge.target,
            rewardPoints: challenge.rewardPoints,
            rewardExp: challenge.rewardExp,
            tags: challenge.tags,
            progress: progress,
            cleared: progress >= challenge.target,
          ),
        );
      } else {
        updated.add(challenge);
      }
    }
    _progressState = ProgressState(
      weakItems: _progressState.weakItems,
      ownedRewards: _progressState.ownedRewards,
      dailyChallenges: updated,
      results: _progressState.results,
    );
  }

  void _upsertWeakItem({
    required String subject,
    required String questionId,
    required String label,
  }) {
    final items = [..._progressState.weakItems];
    final index = items.indexWhere(
      (item) => item.subject == subject && item.questionId == questionId,
    );
    if (index >= 0) {
      final existing = items[index];
      items[index] = WeakItem(
        subject: existing.subject,
        questionId: existing.questionId,
        label: existing.label,
        mistakeCount: existing.mistakeCount + 1,
        lastMistakenAt: DateTime.now(),
      );
    } else {
      items.add(
        WeakItem(
          subject: subject,
          questionId: questionId,
          label: label,
          mistakeCount: 1,
          lastMistakenAt: DateTime.now(),
        ),
      );
    }
    _progressState = ProgressState(
      weakItems: items,
      ownedRewards: _progressState.ownedRewards,
      dailyChallenges: _progressState.dailyChallenges,
      results: _progressState.results,
    );
  }

  void _appendResult({
    required String subject,
    required bool correct,
    required int pointsEarned,
    required int experienceEarned,
    required int comboMax,
  }) {
    final results = [..._progressState.results];
    results.insert(
      0,
      ResultSummary(
        subject: subject,
        totalCount: 1,
        correctCount: correct ? 1 : 0,
        pointsEarned: pointsEarned,
        experienceEarned: experienceEarned,
        comboMax: comboMax,
      ),
    );
    if (results.length > 100) {
      results.removeRange(100, results.length);
    }
    _progressState = ProgressState(
      weakItems: _progressState.weakItems,
      ownedRewards: _progressState.ownedRewards,
      dailyChallenges: _progressState.dailyChallenges,
      results: results,
    );
  }

  AppProfile _applyLevelUp(AppProfile profile) {
    var nextProfile = profile;
    while (nextProfile.experience >= nextProfile.level * 100) {
      nextProfile = nextProfile.copyWith(
        level: nextProfile.level + 1,
        experience: nextProfile.experience - nextProfile.level * 100,
      );
    }
    return nextProfile;
  }

  Future<void> _persistProfile() async {
    await AppStorage.instance.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> _persist() async {
    await AppStorage.instance.saveProfile(_profile);
    await AppStorage.instance.saveProgressState(_progressState);
    notifyListeners();
  }

  num? _parseMathAnswer(String responseText) {
    final normalized = responseText.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.length != 2) {
        return null;
      }
      final numerator = num.tryParse(parts[0].trim());
      final denominator = num.tryParse(parts[1].trim());
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }
    return num.tryParse(normalized);
  }

  bool _numbersMatch(num a, num b) {
    final diff = (a.toDouble() - b.toDouble()).abs();
    return diff < 0.000001;
  }
}
