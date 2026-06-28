import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class KanjiQuestApp extends StatelessWidget {
  const KanjiQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '漢字・計算ドリル Ver2.0',
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
