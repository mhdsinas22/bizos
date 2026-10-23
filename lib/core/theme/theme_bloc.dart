import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}

class LoadThemeEvent extends ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class SetThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  SetThemeEvent(this.themeMode);
}

// States
class ThemeState {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isLightMode => themeMode == ThemeMode.light;
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String prefThemeKey = 'theme_mode_preference';
  static const String prefIsDarkKey = 'is_dark_mode';
  static const String _boxName = 'settings_box';
  static const String _themeKey = 'theme_mode';

  ThemeBloc({ThemeMode initialMode = ThemeMode.light})
    : super(ThemeState(initialMode)) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<SetThemeEvent>(_onSetTheme);
    on<ToggleThemeEvent>(_onToggleTheme);
  }

  /// Restores the saved theme preference during app startup before rendering main UI.
  /// Strict default is ThemeMode.light when no preference exists or on first launch.
  static Future<ThemeMode> getInitialThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check explicit string preference ('light' / 'dark')
      final savedString = prefs.getString(prefThemeKey)?.trim().toLowerCase();
      if (savedString == 'dark') {
        return ThemeMode.dark;
      } else if (savedString == 'light') {
        return ThemeMode.light;
      }

      // 2. Check boolean is_dark_mode preference
      if (prefs.containsKey(prefIsDarkKey)) {
        final isDark = prefs.getBool(prefIsDarkKey);
        if (isDark == true) {
          return ThemeMode.dark;
        } else if (isDark == false) {
          return ThemeMode.light;
        }
      }

      // 3. Fallback check for legacy Hive box if initialized
      try {
        if (Hive.isBoxOpen(_boxName)) {
          final box = Hive.box(_boxName);
          final dynamic val = box.get(_themeKey);
          if (val is bool) {
            return val ? ThemeMode.dark : ThemeMode.light;
          }
        }
      } catch (_) {}

      // Default strictly to Light Mode (do not follow system theme)
      return ThemeMode.light;
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final mode = await getInitialThemeMode();
    emit(ThemeState(mode));
  }

  Future<void> _onSetTheme(
    SetThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final newMode = event.themeMode;
    emit(ThemeState(newMode));
    await _persistTheme(newMode);
  }

  Future<void> _onToggleTheme(
    ToggleThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final isDark = state.themeMode == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    emit(ThemeState(newMode));
    await _persistTheme(newMode);
  }

  static Future<void> _persistTheme(ThemeMode mode) async {
    final isDark = mode == ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefThemeKey, isDark ? 'dark' : 'light');
      await prefs.setBool(prefIsDarkKey, isDark);
    } catch (_) {}

    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        await box.put(_themeKey, isDark);
      }
    } catch (_) {}
  }
}
