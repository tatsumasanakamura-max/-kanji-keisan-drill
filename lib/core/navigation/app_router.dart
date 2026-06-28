import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/challenge/daily_challenge_screen.dart';
import '../../features/encyclopedia/encyclopedia_screen.dart';
import '../../features/grade/grade_select_screen.dart';
import '../../features/gacha/gacha_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/math/math_drill_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/weakness/weakness_screen.dart';
import '../../features/writing/kanji_writing_screen.dart';
import '../../features/reading/kanji_reading_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
    GoRoute(
      path: '/grade',
      builder: (BuildContext context, GoRouterState state) =>
          const GradeSelectScreen(),
    ),
    GoRoute(
      path: '/kanji-reading',
      builder: (BuildContext context, GoRouterState state) =>
          const KanjiReadingScreen(),
    ),
    GoRoute(
      path: '/kanji-writing',
      builder: (BuildContext context, GoRouterState state) =>
          const KanjiWritingScreen(),
    ),
    GoRoute(
      path: '/math-drill',
      builder: (BuildContext context, GoRouterState state) =>
          const MathDrillScreen(),
    ),
    GoRoute(
      path: '/challenge',
      builder: (BuildContext context, GoRouterState state) =>
          const DailyChallengeScreen(),
    ),
    GoRoute(
      path: '/gacha',
      builder: (BuildContext context, GoRouterState state) =>
          const GachaScreen(),
    ),
    GoRoute(
      path: '/encyclopedia',
      builder: (BuildContext context, GoRouterState state) =>
          const EncyclopediaScreen(),
    ),
    GoRoute(
      path: '/weakness',
      builder: (BuildContext context, GoRouterState state) =>
          const WeaknessScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (BuildContext context, GoRouterState state) =>
          const ResultsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
  ],
);
