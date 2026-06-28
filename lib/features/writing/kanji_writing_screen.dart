import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/question_models.dart';
import '../../core/state/game_controller.dart';
import '../../core/state/game_scope.dart';
import '../shared/app_scaffold.dart';

enum _WritingTool { pen, eraser }

class WritingStroke {
  WritingStroke({
    required this.points,
    required this.width,
  });

  final List<Offset> points;
  final double width;
}

class KanjiWritingScreen extends StatefulWidget {
  const KanjiWritingScreen({super.key});

  @override
  State<KanjiWritingScreen> createState() => _KanjiWritingScreenState();
}

class _KanjiWritingScreenState extends State<KanjiWritingScreen> {
  final List<WritingStroke> _strokes = <WritingStroke>[];
  WritingStroke? _activeStroke;
  int _index = 0;
  bool _submitted = false;
  bool _isDrawing = false;
  _WritingTool _tool = _WritingTool.pen;
  double _penWidth = 6;
  QuizResult? _feedback;

  List<KanjiWritingPrompt> get _items => GameScope.of(context).writingPrompts;

  @override
  Widget build(BuildContext context) {
    final controller = GameScope.of(context);
    final items = _items;
    final prompt = items.isEmpty ? null : items[_index % items.length];

    return AppScaffold(
      title: '漢字書き練習',
      child: prompt == null
          ? const Center(child: Text('書き練習の問題が読み込まれていません。'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PromptPanel(
                  prompt: prompt,
                  strokeCount: prompt.strokeCount,
                  submitted: _submitted,
                  feedback: _feedback,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF7),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) =>
                            _handlePointerDown(event.localPosition),
                        onPointerMove: (event) {
                          if (event.buttons == 0) {
                            return;
                          }
                          _handlePointerMove(event.localPosition);
                        },
                        onPointerUp: (_) => _finishStroke(),
                        onPointerCancel: (_) => _finishStroke(),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _WritingBoardPainter(
                                strokes: _strokes,
                                activeStroke: _activeStroke,
                                prompt: prompt,
                              ),
                            ),
                            if (!_submitted)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.72),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          child: Text('指でもタッチペンでも書けます'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (_submitted)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.white.withOpacity(0.14),
                                  alignment: Alignment.center,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x1A000000),
                                          blurRadius: 24,
                                          offset: Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'できた！',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '+${_feedback?.pointsEarned ?? 15} pt  '
                                            '+${_feedback?.experienceEarned ?? 15} 経験値  '
                                            'コンボ ${_feedback?.combo ?? controller.profile.combo}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ToolBar(
                  tool: _tool,
                  penWidth: _penWidth,
                  canUndo: _strokes.isNotEmpty || _activeStroke != null,
                  onToolChanged: (tool) {
                    setState(() {
                      _tool = tool;
                    });
                  },
                  onPenWidthChanged: (width) {
                    setState(() {
                      _penWidth = width;
                    });
                  },
                  onUndo: _undoLastStroke,
                  onEraserTap: () {
                    setState(() {
                      _tool = _tool == _WritingTool.eraser
                          ? _WritingTool.pen
                          : _WritingTool.eraser;
                    });
                  },
                  onClear: _clearCanvas,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: FilledButton.icon(
                          onPressed: _submitted
                              ? null
                              : () async {
                                  HapticFeedback.mediumImpact();
                                  final result = await controller
                                      .completeWritingPractice(prompt);
                                  if (!mounted) {
                                    return;
                                  }
                                  setState(() {
                                    _submitted = true;
                                    _feedback = result;
                                    _isDrawing = false;
                                  });
                                },
                          icon: const Icon(Icons.verified),
                          label: const Text('できた'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _submitted
                              ? () {
                                  HapticFeedback.selectionClick();
                                  _nextPrompt();
                                }
                              : null,
                          icon: const Icon(Icons.navigate_next),
                          label: const Text('次の問題'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _handlePointerDown(Offset position) {
    if (_submitted) {
      return;
    }
    HapticFeedback.selectionClick();
    if (_tool == _WritingTool.eraser) {
      setState(() {
        _eraseAt(position);
      });
      return;
    }
    setState(() {
      _isDrawing = true;
      _activeStroke =
          WritingStroke(points: <Offset>[position], width: _penWidth);
      _strokes.add(_activeStroke!);
    });
  }

  void _handlePointerMove(Offset position) {
    if (_submitted) {
      return;
    }
    if (_tool == _WritingTool.eraser) {
      setState(() {
        _eraseAt(position);
      });
      return;
    }
    if (!_isDrawing || _activeStroke == null) {
      return;
    }
    setState(() {
      final lastPoint =
          _activeStroke!.points.isEmpty ? null : _activeStroke!.points.last;
      if (lastPoint == null || (lastPoint - position).distance >= 1.25) {
        _activeStroke!.points.add(position);
      }
    });
  }

  void _finishStroke() {
    if (_submitted) {
      return;
    }
    setState(() {
      _isDrawing = false;
      _activeStroke = null;
    });
  }

  void _undoLastStroke() {
    if (_submitted) {
      return;
    }
    setState(() {
      if (_activeStroke != null) {
        _strokes.remove(_activeStroke);
        _activeStroke = null;
        _isDrawing = false;
      } else if (_strokes.isNotEmpty) {
        _strokes.removeLast();
      }
    });
  }

  void _clearCanvas() {
    if (_submitted) {
      return;
    }
    setState(() {
      _strokes.clear();
      _activeStroke = null;
      _isDrawing = false;
    });
  }

  void _eraseAt(Offset position) {
    const eraseRadius = 18.0;
    _strokes.removeWhere((stroke) => stroke.points
        .any((point) => (point - position).distance <= eraseRadius));
    if (_activeStroke != null &&
        _activeStroke!.points
            .any((point) => (point - position).distance <= eraseRadius)) {
      _strokes.remove(_activeStroke);
      _activeStroke = null;
      _isDrawing = false;
    }
  }

  void _nextPrompt() {
    final items = _items;
    if (items.isEmpty) {
      return;
    }
    setState(() {
      _index = (_index + 1) % items.length;
      _strokes.clear();
      _activeStroke = null;
      _isDrawing = false;
      _submitted = false;
      _feedback = null;
      _tool = _WritingTool.pen;
      _penWidth = 6;
    });
  }
}

class _PromptPanel extends StatelessWidget {
  const _PromptPanel({
    required this.prompt,
    required this.strokeCount,
    required this.submitted,
    required this.feedback,
  });

  final KanjiWritingPrompt prompt;
  final int strokeCount;
  final bool submitted;
  final QuizResult? feedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '書き練習',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  prompt.kanji,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _InfoChip(label: '読み', value: prompt.reading),
                _InfoChip(label: '画数', value: '$strokeCount'),
                _InfoChip(label: '学年', value: prompt.grade.toString()),
                _InfoChip(label: 'ヒント', value: prompt.hint),
              ],
            ),
            if (submitted && feedback != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '報酬: +${feedback!.pointsEarned} pt, +${feedback!.experienceEarned} 経験値',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.tool,
    required this.penWidth,
    required this.canUndo,
    required this.onToolChanged,
    required this.onPenWidthChanged,
    required this.onUndo,
    required this.onEraserTap,
    required this.onClear,
  });

  final _WritingTool tool;
  final double penWidth;
  final bool canUndo;
  final ValueChanged<_WritingTool> onToolChanged;
  final ValueChanged<double> onPenWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onEraserTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_WritingTool>(
              segments: const [
                ButtonSegment(
                  value: _WritingTool.pen,
                  icon: Icon(Icons.edit),
                  label: Text('ペン'),
                ),
                ButtonSegment(
                  value: _WritingTool.eraser,
                  icon: Icon(Icons.auto_fix_off),
                  label: Text('消しゴム'),
                ),
              ],
              selected: <_WritingTool>{tool},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onToolChanged(selection.first);
                }
              },
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('細め'),
                  selected: penWidth == 4,
                  onSelected: (_) => onPenWidthChanged(4),
                ),
                ChoiceChip(
                  label: const Text('ふつう'),
                  selected: penWidth == 6,
                  onSelected: (_) => onPenWidthChanged(6),
                ),
                ChoiceChip(
                  label: const Text('太め'),
                  selected: penWidth == 9,
                  onSelected: (_) => onPenWidthChanged(9),
                ),
              ],
            ),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo),
                label: const Text('1つ戻る'),
              ),
            ),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
                label: const Text('全消去'),
              ),
            ),
            SizedBox(
              height: 50,
              child: TextButton.icon(
                onPressed: onEraserTap,
                icon: const Icon(Icons.auto_fix_off),
                label: const Text('消しゴム切替'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WritingBoardPainter extends CustomPainter {
  _WritingBoardPainter({
    required this.strokes,
    required this.activeStroke,
    required this.prompt,
  });

  final List<WritingStroke> strokes;
  final WritingStroke? activeStroke;
  final KanjiWritingPrompt prompt;

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Offset.zero & size;
    canvas.drawRect(outerRect, Paint()..color = const Color(0xFFFFFCF7));

    final gridPadding = math.min(size.width, size.height) * 0.06;
    final boardRect = Rect.fromLTWH(
      gridPadding,
      gridPadding,
      size.width - gridPadding * 2,
      size.height - gridPadding * 2,
    );
    final boardRRect =
        RRect.fromRectAndRadius(boardRect, const Radius.circular(24));

    canvas.drawRRect(
      boardRRect,
      Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      boardRRect,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final innerRect = boardRect.deflate(boardRect.shortestSide * 0.1);
    final gridPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final centerPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final thirdWidth = innerRect.width / 3;
    final thirdHeight = innerRect.height / 3;
    for (var i = 1; i < 3; i++) {
      final dx = innerRect.left + thirdWidth * i;
      final dy = innerRect.top + thirdHeight * i;
      canvas.drawLine(
          Offset(dx, innerRect.top), Offset(dx, innerRect.bottom), gridPaint);
      canvas.drawLine(
          Offset(innerRect.left, dy), Offset(innerRect.right, dy), gridPaint);
    }
    canvas.drawLine(
      Offset(innerRect.center.dx, innerRect.top),
      Offset(innerRect.center.dx, innerRect.bottom),
      centerPaint,
    );
    canvas.drawLine(
      Offset(innerRect.left, innerRect.center.dy),
      Offset(innerRect.right, innerRect.center.dy),
      centerPaint,
    );

    final guideSpan = TextSpan(
      text: prompt.kanji,
      style: TextStyle(
        color: const Color(0xFF0F172A).withOpacity(0.08),
        fontSize: innerRect.shortestSide * 0.58,
        fontWeight: FontWeight.w700,
      ),
    );
    final guidePainter = TextPainter(
      text: guideSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: innerRect.width);
    guidePainter.paint(
      canvas,
      Offset(
        innerRect.center.dx - guidePainter.width / 2,
        innerRect.center.dy - guidePainter.height / 2,
      ),
    );

    for (final stroke in strokes) {
      _paintStroke(canvas, stroke, Colors.black87);
    }
    if (activeStroke != null && !strokes.contains(activeStroke)) {
      _paintStroke(canvas, activeStroke!, Colors.black87);
    }
  }

  void _paintStroke(Canvas canvas, WritingStroke stroke, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < stroke.points.length - 1; i++) {
      canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
    }
    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first, stroke.width / 2,
          paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _WritingBoardPainter oldDelegate) {
    return true;
  }
}
