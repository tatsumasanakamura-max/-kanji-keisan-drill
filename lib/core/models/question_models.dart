enum QuestionSubject {
  kanjiReading,
  kanjiWriting,
  math,
}

enum QuestionType {
  reading('reading'),
  writing('writing'),
  compound('compound'),
  sentence('sentence'),
  homophone('homophone'),
  opposite('opposite'),
  synonym('synonym'),
  yojijukugo('yojijukugo'),
  radical('radical'),
  correction('correction');

  const QuestionType(this.code);

  final String code;

  static QuestionType fromCode(String code) {
    return QuestionType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => QuestionType.reading,
    );
  }
}

enum StudyMode {
  normal('通常学習'),
  weakness('苦手克服'),
  reviewToday('今日の復習'),
  test10('10問テスト'),
  mock50('50問模試'),
  random100('ランダム100問');

  const StudyMode(this.label);

  final String label;
}

enum StudyCourseType {
  grade,
  kanken,
}

class StudyCourse {
  const StudyCourse.grade(this.value) : type = StudyCourseType.grade;
  const StudyCourse.kanken(this.value) : type = StudyCourseType.kanken;

  final StudyCourseType type;
  final int value;

  String get assetPath {
    return switch (type) {
      StudyCourseType.grade => 'assets/data/grade$value.json',
      StudyCourseType.kanken => 'assets/data/kanken$value.json',
    };
  }

  String get cacheKey {
    return switch (type) {
      StudyCourseType.grade => 'grade$value',
      StudyCourseType.kanken => 'kanken$value',
    };
  }

  String get label {
    return switch (type) {
      StudyCourseType.grade => '小学$value年',
      StudyCourseType.kanken => '漢検$value級',
    };
  }
}

class DrillQuestion {
  DrillQuestion({
    required this.id,
    required this.grade,
    required this.kanken,
    required this.difficulty,
    required this.type,
    required this.question,
    required this.choices,
    required this.answer,
    required this.meaning,
    required this.example,
    required this.tags,
    this.prompt = '',
    this.sentence = '',
    this.target = '',
    this.answerText = '',
    this.reading = '',
    this.mnemonic = '',
    this.synonyms = const <String>[],
    this.antonyms = const <String>[],
  });

  final String id;
  final int grade;
  final int kanken;
  final int difficulty;
  final QuestionType type;
  final String question;
  final List<String> choices;
  final int answer;
  final String meaning;
  final String example;
  final List<String> tags;
  final String prompt;
  final String sentence;
  final String target;
  final String answerText;
  final String reading;
  final String mnemonic;
  final List<String> synonyms;
  final List<String> antonyms;

  String get answerLabel => choices[answer];
  String get displayPrompt {
    if (prompt.trim().isNotEmpty) {
      return prompt;
    }
    return switch (type) {
      QuestionType.reading => '線を引いた言葉の読みを選びなさい。',
      QuestionType.writing => '線を引いた言葉を漢字で書きなさい。',
      QuestionType.compound => '文に合うように、□に入る漢字を選びなさい。',
      QuestionType.sentence => '文の意味に合う言葉を選びなさい。',
      QuestionType.homophone => '文の意味に合う漢字を選びなさい。',
      QuestionType.opposite => '線を引いた言葉と反対の意味の言葉を選びなさい。',
      QuestionType.synonym => '線を引いた言葉と意味が近い言葉を選びなさい。',
      QuestionType.yojijukugo => '文に合う四字熟語を選びなさい。',
      QuestionType.radical => '線を引いた漢字の部首を選びなさい。',
      QuestionType.correction => '正しい表記を選びなさい。',
    };
  }

  String get displaySentence =>
      sentence.trim().isNotEmpty ? sentence : question;

  factory DrillQuestion.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>).cast<String>();
    final answer = json['answer'] as int;
    if (answer < 0 || answer >= choices.length) {
      throw ArgumentError('answer index is out of range: ${json['id']}');
    }
    return DrillQuestion(
      id: json['id'] as String,
      grade: json['grade'] as int,
      kanken: json['kanken'] as int,
      difficulty: json['difficulty'] as int,
      type: QuestionType.fromCode(json['type'] as String),
      question: json['question'] as String,
      choices: choices,
      answer: answer,
      meaning: json['meaning'] as String? ?? '',
      example: json['example'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
      prompt: json['prompt'] as String? ?? '',
      sentence: json['sentence'] as String? ?? '',
      target: json['target'] as String? ?? '',
      answerText: json['answer_text'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      mnemonic: json['mnemonic'] as String? ?? '',
      synonyms:
          (json['synonyms'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
      antonyms:
          (json['antonyms'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'grade': grade,
        'kanken': kanken,
        'difficulty': difficulty,
        'type': type.code,
        'question': question,
        if (prompt.isNotEmpty) 'prompt': prompt,
        if (sentence.isNotEmpty) 'sentence': sentence,
        if (target.isNotEmpty) 'target': target,
        if (answerText.isNotEmpty) 'answer_text': answerText,
        if (reading.isNotEmpty) 'reading': reading,
        'choices': choices,
        'answer': answer,
        'meaning': meaning,
        'example': example,
        'mnemonic': mnemonic,
        'synonyms': synonyms,
        'antonyms': antonyms,
        'tags': tags,
      };
}

class GradeQuestionSet {
  GradeQuestionSet({
    required this.grade,
    required this.label,
    required this.drillQuestions,
    required this.kanjiReadingQuestions,
    required this.kanjiWritingPrompts,
    required this.mathQuestions,
  });

  final int grade;
  final String label;
  final List<DrillQuestion> drillQuestions;
  final List<KanjiReadingQuestion> kanjiReadingQuestions;
  final List<KanjiWritingPrompt> kanjiWritingPrompts;
  final List<MathQuestion> mathQuestions;

  factory GradeQuestionSet.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic value) =>
            DrillQuestion.fromJson(value as Map<String, dynamic>))
        .toList();
    return GradeQuestionSet(
      grade: json['grade'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      drillQuestions: questions,
      kanjiReadingQuestions: questions
          .where((question) => question.type == QuestionType.reading)
          .map(KanjiReadingQuestion.fromDrillQuestion)
          .toList(),
      kanjiWritingPrompts: questions
          .where((question) => question.type == QuestionType.writing)
          .map(KanjiWritingPrompt.fromDrillQuestion)
          .toList(),
      mathQuestions: (json['mathQuestions'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic value) =>
              MathQuestion.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }
}

class KanjiReadingQuestion {
  KanjiReadingQuestion({
    required this.id,
    required this.grade,
    required this.kanji,
    required this.reading,
    required this.meaning,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    required this.tags,
    required this.source,
  });

  final String id;
  final int grade;
  final String kanji;
  final String reading;
  final String meaning;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final List<String> tags;
  final DrillQuestion source;

  factory KanjiReadingQuestion.fromDrillQuestion(DrillQuestion question) {
    return KanjiReadingQuestion(
      id: question.id,
      grade: question.grade,
      kanji: question.answerText.isNotEmpty
          ? question.answerText
          : question.target.isNotEmpty
              ? question.target
              : question.question,
      reading: question.answerLabel,
      meaning: question.meaning,
      options: question.choices,
      answerIndex: question.answer,
      explanation: question.example,
      tags: question.tags,
      source: question,
    );
  }
}

class KanjiWritingPrompt {
  KanjiWritingPrompt({
    required this.id,
    required this.grade,
    required this.kanji,
    required this.reading,
    required this.strokeCount,
    required this.hint,
    required this.strokeOrderNotes,
    required this.tags,
    required this.prompt,
    required this.sentence,
    required this.target,
  });

  final String id;
  final int grade;
  final String kanji;
  final String reading;
  final int strokeCount;
  final String hint;
  final String strokeOrderNotes;
  final List<String> tags;
  final String prompt;
  final String sentence;
  final String target;

  factory KanjiWritingPrompt.fromDrillQuestion(DrillQuestion question) {
    return KanjiWritingPrompt(
      id: question.id,
      grade: question.grade,
      kanji: question.answerText.isNotEmpty
          ? question.answerText
          : question.answerLabel,
      reading: question.target.isNotEmpty ? question.target : question.question,
      strokeCount: int.tryParse(
            question.tags
                .firstWhere((tag) => tag.startsWith('strokes:'),
                    orElse: () => 'strokes:0')
                .split(':')
                .last,
          ) ??
          0,
      hint: question.meaning,
      strokeOrderNotes: question.example,
      tags: question.tags,
      prompt: question.displayPrompt,
      sentence: question.displaySentence,
      target: question.target,
    );
  }
}

class MathQuestion {
  MathQuestion({
    required this.id,
    required this.grade,
    required this.expression,
    required this.answer,
    required this.options,
    required this.operation,
    required this.explanation,
    required this.tags,
  });

  final String id;
  final int grade;
  final String expression;
  final num answer;
  final List<num> options;
  final String operation;
  final String explanation;
  final List<String> tags;

  factory MathQuestion.fromJson(Map<String, dynamic> json) {
    return MathQuestion(
      id: json['id'] as String,
      grade: json['grade'] as int,
      expression: json['expression'] as String,
      answer: json['answer'] as num,
      options: (json['options'] as List<dynamic>)
          .map((value) => value as num)
          .toList(),
      operation: json['operation'] as String,
      explanation: json['explanation'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }
}
