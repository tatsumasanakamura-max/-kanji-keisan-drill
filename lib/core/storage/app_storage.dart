import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/progress_models.dart';

class AppStorage {
  AppStorage._();

  static final AppStorage instance = AppStorage._();

  static const String _profileBoxName = 'app_profile';
  static const String _stateBoxName = 'app_state';

  Box<String>? _profileBox;
  Box<String>? _stateBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _profileBox = await Hive.openBox<String>(_profileBoxName);
    _stateBox = await Hive.openBox<String>(_stateBoxName);
  }

  Future<AppProfile> loadProfile() async {
    final raw = _profileBox?.get('profile');
    if (raw == null || raw.isEmpty) {
      return AppProfile.defaultProfile();
    }
    return AppProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(AppProfile profile) async {
    await _profileBox?.put('profile', jsonEncode(profile.toJson()));
  }

  Future<ProgressState> loadProgressState() async {
    final raw = _stateBox?.get('state');
    if (raw == null || raw.isEmpty) {
      return ProgressState.defaultState();
    }
    return ProgressState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProgressState(ProgressState state) async {
    await _stateBox?.put('state', jsonEncode(state.toJson()));
  }

  Future<void> resetAll() async {
    await _profileBox?.clear();
    await _stateBox?.clear();
  }
}
