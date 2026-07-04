import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

// Events
abstract class ThemeEvent {}
class LoadThemeEvent extends ThemeEvent {}
class ToggleThemeEvent extends ThemeEvent {}

// States
class ThemeState {
  final ThemeMode themeMode;
  ThemeState(this.themeMode);
}

// BLoC
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _boxName = 'settings_box';
  static const String _themeKey = 'theme_mode';

  ThemeBloc() : super(ThemeState(ThemeMode.system)) {
    on<LoadThemeEvent>((event, emit) async {
      final box = await Hive.openBox(_boxName);
      final isDark = box.get(_themeKey, defaultValue: false) as bool;
      emit(ThemeState(isDark ? ThemeMode.dark : ThemeMode.light));
    });

    on<ToggleThemeEvent>((event, emit) async {
      final box = await Hive.openBox(_boxName);
      final isDark = state.themeMode == ThemeMode.dark;
      final newIsDark = !isDark;
      await box.put(_themeKey, newIsDark);
      emit(ThemeState(newIsDark ? ThemeMode.dark : ThemeMode.light));
    });
  }
}
