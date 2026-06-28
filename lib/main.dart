import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/question_repository.dart';
import 'core/storage/app_storage.dart';
import 'core/state/game_controller.dart';
import 'core/state/game_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.instance.initialize();
  await QuestionRepository.instance.load();
  await GameController.instance.initialize();
  runApp(
    GameScope(
      controller: GameController.instance,
      child: const KanjiQuestApp(),
    ),
  );
}
