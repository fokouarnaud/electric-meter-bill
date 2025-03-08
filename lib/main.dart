// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'injection.dart';
import 'presentation/bloc/meter/meter_bloc.dart';
import 'presentation/bloc/meter/meter_event.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'presentation/bloc/theme/theme_event.dart';
import 'presentation/bloc/language/language_bloc.dart';
import 'presentation/bloc/language/language_event.dart';
import 'presentation/bloc/currency/currency_bloc.dart';
import 'presentation/bloc/currency/currency_event.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDependencies(
    currencyApiKey: const String.fromEnvironment(
      'CURRENCY_API_KEY',
      defaultValue: 'cur_live_pGNJsPNeOxWJzPu4JbcckS0iJqZqcTx8XCYD5S8i',
    ),
  );
  
  // Vérifier si l'utilisateur a déjà vu l'onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  
  runApp(MyApp(onboardingCompleted: onboardingCompleted));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  
  const MyApp({
    super.key,
    required this.onboardingCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()..add(LoadTheme())),
        BlocProvider(create: (_) => getIt<MeterBloc>()..add(LoadMeters())),
        BlocProvider(create: (_) => getIt<LanguageBloc>()..add(const LoadLanguage())),
        BlocProvider(create: (_) => getIt<CurrencyBloc>()..add(LoadCurrency())),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false, // Enlever le bandeau "Debug"
            title: 'Electric Meter Billing',
            onGenerateTitle: (context) => AppLocalizations.of(context)?.appTitle ?? 'Electric Meter Billing',
            theme: ThemeService.getLightTheme(),
            darkTheme: ThemeService.getDarkTheme(),
            themeMode: context.watch<ThemeBloc>().state.themeMode,
            locale: context.watch<LanguageBloc>().state.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            home: onboardingCompleted 
                ? const HomeScreen()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}