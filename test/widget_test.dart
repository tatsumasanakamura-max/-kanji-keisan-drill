import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_keisan_quest/app.dart';
import 'package:kanji_keisan_quest/core/state/game_controller.dart';
import 'package:kanji_keisan_quest/core/state/game_scope.dart';

void main() {
  testWidgets('app can be constructed', (WidgetTester tester) async {
    await tester.pumpWidget(
      GameScope(
        controller: GameController.instance,
        child: const KanjiQuestApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
