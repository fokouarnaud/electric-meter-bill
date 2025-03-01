import 'package:flutter/material.dart';

abstract class LanguageEvent {
  const LanguageEvent();
}

class LoadLanguage extends LanguageEvent {
  const LoadLanguage();
}

class ChangeLanguage extends LanguageEvent {
  final Locale locale;

  const ChangeLanguage(this.locale);
}
