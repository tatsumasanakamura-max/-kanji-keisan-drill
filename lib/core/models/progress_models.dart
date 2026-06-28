class AppProfile {
  AppProfile({
    required this.userName,
    required this.selectedGrade,
    required this.selectedKanken,
    required this.useKankenMode,
    required this.points,
    required this.experience,
    required this.level,
    required this.combo,
    required this.bestCombo,
    required this.totalSolved,
    required this.correctCount,
    required this.writingPracticeCount,
    required this.currentStreak,
    required this.studyStreakDays,
    required this.lastPlayedAt,
  });

  final String userName;
  final int selectedGrade;
  final int selectedKanken;
  final bool useKankenMode;
  final int points;
  final int experience;
  final int level;
  final int combo;
  final int bestCombo;
  final int totalSolved;
  final int correctCount;
  final int writingPracticeCount;
  final int currentStreak;
  final int studyStreakDays;
  final DateTime? lastPlayedAt;

  factory AppProfile.defaultProfile() {
    return AppProfile(
      userName: 'プレイヤー',
      selectedGrade: 1,
      selectedKanken: 10,
      useKankenMode: false,
      points: 0,
      experience: 0,
      level: 1,
      combo: 0,
      bestCombo: 0,
      totalSolved: 0,
      correctCount: 0,
      writingPracticeCount: 0,
      currentStreak: 0,
      studyStreakDays: 0,
      lastPlayedAt: null,
    );
  }

  AppProfile copyWith({
    String? userName,
    int? selectedGrade,
    int? selectedKanken,
    bool? useKankenMode,
    int? points,
    int? experience,
    int? level,
    int? combo,
    int? bestCombo,
    int? totalSolved,
    int? correctCount,
    int? writingPracticeCount,
    int? currentStreak,
    int? studyStreakDays,
    DateTime? lastPlayedAt,
    bool clearLastPlayedAt = false,
  }) {
    return AppProfile(
      userName: userName ?? this.userName,
      selectedGrade: selectedGrade ?? this.selectedGrade,
      selectedKanken: selectedKanken ?? this.selectedKanken,
      useKankenMode: useKankenMode ?? this.useKankenMode,
      points: points ?? this.points,
      experience: experience ?? this.experience,
      level: level ?? this.level,
      combo: combo ?? this.combo,
      bestCombo: bestCombo ?? this.bestCombo,
      totalSolved: totalSolved ?? this.totalSolved,
      correctCount: correctCount ?? this.correctCount,
      writingPracticeCount: writingPracticeCount ?? this.writingPracticeCount,
      currentStreak: currentStreak ?? this.currentStreak,
      studyStreakDays: studyStreakDays ?? this.studyStreakDays,
      lastPlayedAt:
          clearLastPlayedAt ? null : (lastPlayedAt ?? this.lastPlayedAt),
    );
  }

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      userName: json['userName'] as String? ?? 'プレイヤー',
      selectedGrade: json['selectedGrade'] as int? ?? 1,
      selectedKanken: json['selectedKanken'] as int? ?? 10,
      useKankenMode: json['useKankenMode'] as bool? ?? false,
      points: json['points'] as int? ?? 0,
      experience: json['experience'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      combo: json['combo'] as int? ?? 0,
      bestCombo: json['bestCombo'] as int? ?? 0,
      totalSolved: json['totalSolved'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      writingPracticeCount: json['writingPracticeCount'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      studyStreakDays: json['studyStreakDays'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] == null
          ? null
          : DateTime.parse(json['lastPlayedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userName': userName,
        'selectedGrade': selectedGrade,
        'selectedKanken': selectedKanken,
        'useKankenMode': useKankenMode,
        'points': points,
        'experience': experience,
        'level': level,
        'combo': combo,
        'bestCombo': bestCombo,
        'totalSolved': totalSolved,
        'correctCount': correctCount,
        'writingPracticeCount': writingPracticeCount,
        'currentStreak': currentStreak,
        'studyStreakDays': studyStreakDays,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      };
}

class WeakItem {
  WeakItem({
    required this.subject,
    required this.questionId,
    required this.label,
    required this.mistakeCount,
    required this.correctCount,
    required this.totalCount,
    required this.totalAnswerMillis,
    required this.consecutiveWrong,
    required this.consecutiveCorrect,
    required this.lastMistakenAt,
    required this.lastAnsweredAt,
  });

  final String subject;
  final String questionId;
  final String label;
  final int mistakeCount;
  final int correctCount;
  final int totalCount;
  final int totalAnswerMillis;
  final int consecutiveWrong;
  final int consecutiveCorrect;
  final DateTime? lastMistakenAt;
  final DateTime? lastAnsweredAt;

  double get correctRate => totalCount == 0 ? 0 : correctCount / totalCount;
  int get averageAnswerMillis =>
      totalCount == 0 ? 0 : totalAnswerMillis ~/ totalCount;
  bool get isWeak => mistakeCount > 0 && correctRate < 0.8;

  factory WeakItem.fromJson(Map<String, dynamic> json) {
    return WeakItem(
      subject: json['subject'] as String,
      questionId: json['questionId'] as String,
      label: json['label'] as String,
      mistakeCount: json['mistakeCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      totalAnswerMillis: json['totalAnswerMillis'] as int? ?? 0,
      consecutiveWrong: json['consecutiveWrong'] as int? ?? 0,
      consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
      lastMistakenAt: json['lastMistakenAt'] == null
          ? null
          : DateTime.parse(json['lastMistakenAt'] as String),
      lastAnsweredAt: json['lastAnsweredAt'] == null
          ? null
          : DateTime.parse(json['lastAnsweredAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject': subject,
        'questionId': questionId,
        'label': label,
        'mistakeCount': mistakeCount,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'totalAnswerMillis': totalAnswerMillis,
        'consecutiveWrong': consecutiveWrong,
        'consecutiveCorrect': consecutiveCorrect,
        'lastMistakenAt': lastMistakenAt?.toIso8601String(),
        'lastAnsweredAt': lastAnsweredAt?.toIso8601String(),
      };
}

class ResultSummary {
  ResultSummary({
    required this.subject,
    required this.totalCount,
    required this.correctCount,
    required this.pointsEarned,
    required this.experienceEarned,
    required this.comboMax,
    required this.category,
    required this.grade,
    required this.kanken,
    required this.answerMillis,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  final String subject;
  final int totalCount;
  final int correctCount;
  final int pointsEarned;
  final int experienceEarned;
  final int comboMax;
  final String category;
  final int grade;
  final int kanken;
  final int answerMillis;
  final DateTime answeredAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'subject': subject,
        'totalCount': totalCount,
        'correctCount': correctCount,
        'pointsEarned': pointsEarned,
        'experienceEarned': experienceEarned,
        'comboMax': comboMax,
        'category': category,
        'grade': grade,
        'kanken': kanken,
        'answerMillis': answerMillis,
        'answeredAt': answeredAt.toIso8601String(),
      };

  factory ResultSummary.fromJson(Map<String, dynamic> json) {
    return ResultSummary(
      subject: json['subject'] as String,
      totalCount: json['totalCount'] as int,
      correctCount: json['correctCount'] as int,
      pointsEarned: json['pointsEarned'] as int,
      experienceEarned: json['experienceEarned'] as int,
      comboMax: json['comboMax'] as int,
      category: json['category'] as String? ?? json['subject'] as String,
      grade: json['grade'] as int? ?? 0,
      kanken: json['kanken'] as int? ?? 0,
      answerMillis: json['answerMillis'] as int? ?? 0,
      answeredAt: json['answeredAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['answeredAt'] as String),
    );
  }
}

class EncyclopediaEntry {
  EncyclopediaEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.unlocked = false,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool unlocked;

  factory EncyclopediaEntry.fromJson(Map<String, dynamic> json) {
    return EncyclopediaEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'unlocked': unlocked,
      };
}

class GachaReward {
  GachaReward({
    required this.id,
    required this.name,
    required this.rarity,
    required this.description,
    required this.pointsCost,
  });

  final String id;
  final String name;
  final String rarity;
  final String description;
  final int pointsCost;

  factory GachaReward.fromJson(Map<String, dynamic> json) {
    return GachaReward(
      id: json['id'] as String,
      name: json['name'] as String,
      rarity: json['rarity'] as String,
      description: json['description'] as String,
      pointsCost: json['pointsCost'] as int,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'rarity': rarity,
        'description': description,
        'pointsCost': pointsCost,
      };
}

class DailyChallenge {
  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.rewardPoints,
    required this.rewardExp,
    required this.tags,
    this.progress = 0,
    this.cleared = false,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final int rewardPoints;
  final int rewardExp;
  final List<String> tags;
  final int progress;
  final bool cleared;

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      target: json['target'] as int,
      rewardPoints: json['rewardPoints'] as int,
      rewardExp: json['rewardExp'] as int,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      progress: json['progress'] as int? ?? 0,
      cleared: json['cleared'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'target': target,
        'rewardPoints': rewardPoints,
        'rewardExp': rewardExp,
        'tags': tags,
        'progress': progress,
        'cleared': cleared,
      };
}

class ProgressState {
  ProgressState({
    required this.weakItems,
    required this.ownedRewards,
    required this.dailyChallenges,
    required this.results,
  });

  final List<WeakItem> weakItems;
  final List<GachaReward> ownedRewards;
  final List<DailyChallenge> dailyChallenges;
  final List<ResultSummary> results;

  factory ProgressState.defaultState() {
    return ProgressState(
      weakItems: <WeakItem>[],
      ownedRewards: <GachaReward>[],
      dailyChallenges: <DailyChallenge>[],
      results: <ResultSummary>[],
    );
  }

  factory ProgressState.fromJson(Map<String, dynamic> json) {
    return ProgressState(
      weakItems: (json['weakItems'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic value) =>
              WeakItem.fromJson(value as Map<String, dynamic>))
          .toList(),
      ownedRewards: (json['ownedRewards'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic value) =>
              GachaReward.fromJson(value as Map<String, dynamic>))
          .toList(),
      dailyChallenges:
          (json['dailyChallenges'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic value) =>
                  DailyChallenge.fromJson(value as Map<String, dynamic>))
              .toList(),
      results: (json['results'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic value) =>
              ResultSummary.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'weakItems': weakItems.map((WeakItem item) => item.toJson()).toList(),
        'ownedRewards':
            ownedRewards.map((GachaReward item) => item.toJson()).toList(),
        'dailyChallenges': dailyChallenges
            .map((DailyChallenge item) => item.toJson())
            .toList(),
        'results': results.map((ResultSummary item) => item.toJson()).toList(),
      };
}
