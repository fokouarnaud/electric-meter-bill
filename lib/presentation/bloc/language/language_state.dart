import 'package:flutter/material.dart';

class LanguageState {
  final Locale locale;

  const LanguageState(this.locale);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageState && other.locale == locale;
  }

  @override
  int get hashCode => locale.hashCode;
}
