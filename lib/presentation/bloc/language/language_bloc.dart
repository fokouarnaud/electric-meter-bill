import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/language_service.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageService _languageService;

  LanguageBloc(this._languageService)
      : super(LanguageState(_languageService.getLocale())) {
    on<LoadLanguage>(_onLoadLanguage);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(
      LoadLanguage event, Emitter<LanguageState> emit) async {
    final locale = _languageService.getLocale();
    emit(LanguageState(locale));
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<LanguageState> emit) async {
    await _languageService.setLocale(event.locale);
    emit(LanguageState(event.locale));
  }

  List<Locale> get supportedLocales => _languageService.getSupportedLocales();

  String getLanguageName(String languageCode) =>
      _languageService.getLanguageName(languageCode);
}
