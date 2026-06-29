import 'package:flutter/foundation.dart';

import '../data/question_repository.dart';
import '../models/progress_models.dart';
import '../models/question_models.dart';
import '../services/question_picker.dart';
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

  final QuestionPicker _questionPicker = QuestionPicker();
  AppProfile _profile = AppProfile.defaultProfile();
  ProgressState _progressState = ProgressState.defaultState();
  bool _initialized = false;
  int _currentDifficulty = 1;
  StudyMode _studyMode = StudyMode.normal;
  final Set<String> _answeredQuestionIdsThisSession = <String>{};

  AppProfile get profile => _profile;
  ProgressState get progressState => _progressState;
  bool get isInitialized => _initialized;
  int get currentDifficulty => _currentDifficulty;
  StudyMode get studyMode => _studyMode;

  StudyCourse get selectedCourse {
    return _profile.useKankenMode
        ? StudyCourse.kanken(_profile.selectedKanken)
        : StudyCourse.grade(_profile.selectedGrade);
  }

  Future<GradeQuestionSet> loadGradeQuestions(int grade) {
    return QuestionRepository.instance.loadGrade(grade);
  }

  Future<GradeQuestionSet> loadSelectedCourseQuestions() {
    return QuestionRepository.instance.loadCourse(selectedCourse);
  }

  DrillQuestion pickQuestion(List<DrillQuestion> questions) {
    return _questionPicker.pick(
      questions: questions,
      history: _progressState.weakItems,
      currentDifficulty: _currentDifficulty,
      excludedQuestionIds: _answeredQuestionIdsThisSession,
      mode: _studyMode,
    );
  }

  String gradeLabelFor(int grade) => '小学 $grade 年';
  String kankenLabelFor(int level) => '漢検 $level 級';
  String get selectedCourseLabel => selectedCourse.label;

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
    _currentDifficulty = 1;
    _answeredQuestionIdsThisSession.clear();
    await _persist();
  }

  Future<void> setGrade(int grade) async {
    _profile = _profile.copyWith(selectedGrade: grade, useKankenMode: false);
    _answeredQuestionIdsThisSession.clear();
    await _persistProfile();
  }

  Future<void> setKanken(int level) async {
    _profile = _profile.copyWith(selectedKanken: level, useKankenMode: true);
    _answeredQuestionIdsThisSession.clear();
    await _persistProfile();
  }

  Future<void> setStudyMode(StudyMode mode) async {
    _studyMode = mode;
    _answeredQuestionIdsThisSession.clear();
    notifyListeners();
  }

  Future<QuizResult> answerDrill(
    DrillQuestion question,
    int selectedIndex, {
    int answerMillis = 0,
  }) {
    final correct = selectedIndex == question.answer;
    return _applyAnswer(
      subject: 'kanji_${question.type.code}',
      questionId: question.id,
      label: question.question,
      correct: correct,
      correctAnswerLabel: question.answerLabel,
      category: question.type.code,
      grade: question.grade,
      kanken: question.kanken,
      answerMillis: answerMillis,
    );
  }

  Future<QuizResult> answerReading(
    KanjiReadingQuestion question,
    int selectedIndex, {
    int answerMillis = 0,
  }) {
    final correct = selectedIndex == question.answerIndex;
    return _applyAnswer(
      subject: 'kanji_reading',
      questionId: question.id,
      label: '${question.kanji} (${question.reading})',
      correct: correct,
      correctAnswerLabel: question.options[question.answerIndex],
      category: question.source.type.code,
      grade: question.source.grade,
      kanken: question.source.kanken,
      answerMillis: answerMillis,
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
      category: question.operation,
      grade: question.grade,
      kanken: 0,
    );
  }

  Future<QuizResult> completeWritingPractice(KanjiWritingPrompt prompt) {
    return _applySuccess(
      subject: 'kanji_writing',
      questionId: prompt.id,
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
    required String category,
    required int grade,
    required int kanken,
    int answerMillis = 0,
  }) async {
    final now = DateTime.now();
    final nextStudyStreakDays = _nextStudyStreakDays(now);
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
        studyStreakDays: nextStudyStreakDays,
        lastPlayedAt: now,
      );
      _profile = _applyLevelUp(_profile);
      _incrementDailyProgress(<String>['mixed', category]);
    } else {
      _profile = _profile.copyWith(
        combo: 0,
        totalSolved: _profile.totalSolved + 1,
        currentStreak: 0,
        studyStreakDays: nextStudyStreakDays,
        lastPlayedAt: now,
      );
    }

    _upsertQuestionHistory(
      subject: subject,
      questionId: questionId,
      label: label,
      correct: correct,
      answerMillis: answerMillis,
      now: now,
    );
    _answeredQuestionIdsThisSession.add(questionId);
    _adjustDifficulty(correct);
    _appendResult(
      subject: subject,
      correct: correct,
      pointsEarned: pointsEarned,
      experienceEarned: experienceEarned,
      comboMax: comboForResult,
      category: category,
      grade: grade,
      kanken: kanken,
      answerMillis: answerMillis,
    );
    await _persist();

    return QuizResult(
      correct: correct,
      message: correct ? '正解です' : 'もう一度挑戦しよう',
      pointsEarned: pointsEarned,
      experienceEarned: experienceEarned,
      combo: _profile.combo,
      correctAnswerLabel: correctAnswerLabel,
    );
  }

  Future<QuizResult> _applySuccess({
    required String subject,
    String? questionId,
    required int rewardPoints,
    required int rewardExperience,
    required List<String> dailyTags,
    required String correctAnswerLabel,
  }) async {
    final now = DateTime.now();
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
      studyStreakDays: _nextStudyStreakDays(now),
      lastPlayedAt: now,
    );
    _profile = _applyLevelUp(_profile);
    _incrementDailyProgress(dailyTags);
    if (questionId != null) {
      _answeredQuestionIdsThisSession.add(questionId);
    }
    _appendResult(
      subject: subject,
      correct: true,
      pointsEarned: rewardPoints,
      experienceEarned: rewardExperience,
      comboMax: comboForResult,
      category: 'writing',
      grade: _profile.selectedGrade,
      kanken: _profile.useKankenMode ? _profile.selectedKanken : 0,
      answerMillis: 0,
    );
    await _persist();

    return QuizResult(
      correct: true,
      message: 'よくできました',
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
      updated.add(
        shouldCount
            ? DailyChallenge(
                id: challenge.id,
                title: challenge.title,
                description: challenge.description,
                target: challenge.target,
                rewardPoints: challenge.rewardPoints,
                rewardExp: challenge.rewardExp,
                tags: challenge.tags,
                progress: challenge.progress + 1,
                cleared: challenge.progress + 1 >= challenge.target,
              )
            : challenge,
      );
    }
    _progressState = ProgressState(
      weakItems: _progressState.weakItems,
      ownedRewards: _progressState.ownedRewards,
      dailyChallenges: updated,
      results: _progressState.results,
    );
  }

  void _upsertQuestionHistory({
    required String subject,
    required String questionId,
    required String label,
    required bool correct,
    required int answerMillis,
    required DateTime now,
  }) {
    final items = [..._progressState.weakItems];
    final index = items.indexWhere(
        (item) => item.subject == subject && item.questionId == questionId);
    final existing = index >= 0 ? items[index] : null;
    final updated = WeakItem(
      subject: subject,
      questionId: questionId,
      label: label,
      mistakeCount: (existing?.mistakeCount ?? 0) + (correct ? 0 : 1),
      correctCount: (existing?.correctCount ?? 0) + (correct ? 1 : 0),
      totalCount: (existing?.totalCount ?? 0) + 1,
      totalAnswerMillis: (existing?.totalAnswerMillis ?? 0) + answerMillis,
      consecutiveWrong: correct ? 0 : (existing?.consecutiveWrong ?? 0) + 1,
      consecutiveCorrect: correct ? (existing?.consecutiveCorrect ?? 0) + 1 : 0,
      lastMistakenAt: correct ? existing?.lastMistakenAt : now,
      lastAnsweredAt: now,
    );
    if (index >= 0) {
      items[index] = updated;
    } else {
      items.add(updated);
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
    required String category,
    required int grade,
    required int kanken,
    required int answerMillis,
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
        category: category,
        grade: grade,
        kanken: kanken,
        answerMillis: answerMillis,
      ),
    );
    if (results.length > 500) {
      results.removeRange(500, results.length);
    }
    _progressState = ProgressState(
      weakItems: _progressState.weakItems,
      ownedRewards: _progressState.ownedRewards,
      dailyChallenges: _progressState.dailyChallenges,
      results: results,
    );
  }

  void _adjustDifficulty(bool correct) {
    if (correct &&
        _profile.currentStreak > 0 &&
        _profile.currentStreak % 5 == 0) {
      _currentDifficulty = (_currentDifficulty + 1).clamp(1, 5);
      return;
    }
    final recentWrong = _progressState.results
        .take(2)
        .where((result) => result.correctCount == 0)
        .length;
    if (!correct && recentWrong >= 2) {
      _currentDifficulty = (_currentDifficulty - 1).clamp(1, 5);
    }
  }

  int _nextStudyStreakDays(DateTime now) {
    final last = _profile.lastPlayedAt;
    if (last == null) {
      return 1;
    }
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastDay).inDays;
    if (diff == 0) {
      return _profile.studyStreakDays == 0 ? 1 : _profile.studyStreakDays;
    }
    if (diff == 1) {
      return _profile.studyStreakDays + 1;
    }
    return 1;
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
