enum QuestionSubject {
  kanjiReading,
  kanjiWriting,
  math,
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

  factory KanjiReadingQuestion.fromJson(Map<String, dynamic> json) {
    return KanjiReadingQuestion(
      id: json['id'] as String,
      grade: json['grade'] as int,
      kanji: json['kanji'] as String,
      reading: json['reading'] as String,
      meaning: json['meaning'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      answerIndex: json['answerIndex'] as int,
      explanation: json['explanation'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'grade': grade,
        'kanji': kanji,
        'reading': reading,
        'meaning': meaning,
        'options': options,
        'answerIndex': answerIndex,
        'explanation': explanation,
        'tags': tags,
      };
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
  });

  final String id;
  final int grade;
  final String kanji;
  final String reading;
  final int strokeCount;
  final String hint;
  final String strokeOrderNotes;
  final List<String> tags;

  factory KanjiWritingPrompt.fromJson(Map<String, dynamic> json) {
    return KanjiWritingPrompt(
      id: json['id'] as String,
      grade: json['grade'] as int,
      kanji: json['kanji'] as String,
      reading: json['reading'] as String,
      strokeCount: json['strokeCount'] as int,
      hint: json['hint'] as String,
      strokeOrderNotes: json['strokeOrderNotes'] as String,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'grade': grade,
        'kanji': kanji,
        'reading': reading,
        'strokeCount': strokeCount,
        'hint': hint,
        'strokeOrderNotes': strokeOrderNotes,
        'tags': tags,
      };
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'grade': grade,
        'expression': expression,
        'answer': answer,
        'options': options,
        'operation': operation,
        'explanation': explanation,
        'tags': tags,
      };
}
