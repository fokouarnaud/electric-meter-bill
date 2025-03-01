import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDependencies(
    currencyApiKey: const String.fromEnvironment(
      'CURRENCY_API_KEY',
      defaultValue: 'cur_live_CxNn6u71b6qQAmUKcM9r8NMwTIh0DF0frBU6rQ3Y',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
