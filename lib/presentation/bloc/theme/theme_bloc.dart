import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/theme_service.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(ThemeMode.system)) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    final themeMode = ThemeService.getThemeMode();
    emit(ThemeState(themeMode));
  }

  Future<void> _onChangeTheme(
      ChangeTheme event, Emitter<ThemeState> emit) async {
    await ThemeService.setThemeMode(event.mode);
    emit(ThemeState(event.mode));
  }
}
