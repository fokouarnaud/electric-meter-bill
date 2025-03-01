import 'package:flutter/material.dart';

abstract class ThemeEvent {
  const ThemeEvent();
}

class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

class ChangeTheme extends ThemeEvent {
  final ThemeMode mode;

  const ChangeTheme(this.mode);
}
