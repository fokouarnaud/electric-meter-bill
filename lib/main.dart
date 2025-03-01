import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection.dart';
import 'presentation/bloc/meter/meter_bloc.dart';
import 'presentation/bloc/meter/meter_event.dart';
import 'presentation/bloc/meter_reading/meter_reading_bloc.dart';
import 'presentation/bloc/bill/bill_bloc.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'presentation/bloc/theme/theme_event.dart';
import 'presentation/bloc/theme/theme_state.dart';
import 'presentation/screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await initializeDependencies();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await ThemeService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeBloc()..add(LoadTheme()),
        ),
        BlocProvider(
          create: (_) => getIt<MeterBloc>()..add(LoadMeters()),
        ),
        BlocProvider(
          create: (_) => getIt<MeterReadingBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<BillBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Electric Meter Billing',
            theme: ThemeService.getLightTheme(),
            darkTheme: ThemeService.getDarkTheme(),
            themeMode: themeState.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
