import 'package:flutter/material.dart';

class ContextQuestionText extends StatelessWidget {
  const ContextQuestionText({
    super.key,
    required this.prompt,
    required this.sentence,
    required this.target,
    this.reading,
  });

  final String prompt;
  final String sentence;
  final String target;
  final String? reading;

  @override
  Widget build(BuildContext context) {
    final promptStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );
    final sentenceStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prompt.trim().isNotEmpty) ...[
          Text(prompt, style: promptStyle),
          const SizedBox(height: 10),
        ],
        if (reading != null && reading!.trim().isNotEmpty) ...[
          Text(
            '読み: ${reading!.trim()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        _HighlightedSentence(
          sentence: sentence,
          target: target,
          style: sentenceStyle,
        ),
      ],
    );
  }
}

class _HighlightedSentence extends StatelessWidget {
  const _HighlightedSentence({
    required this.sentence,
    required this.target,
    required this.style,
  });

  final String sentence;
  final String target;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cleanTarget = target.trim();
    final targetIndex =
        cleanTarget.isEmpty ? -1 : sentence.indexOf(cleanTarget);

    if (targetIndex < 0) {
      return Text(sentence, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: sentence.substring(0, targetIndex)),
          TextSpan(
            text: sentence.substring(
                targetIndex, targetIndex + cleanTarget.length),
            style: style?.copyWith(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
          TextSpan(text: sentence.substring(targetIndex + cleanTarget.length)),
        ],
      ),
    );
  }
}
