import 'package:get_it/get_it.dart';
import 'data/datasources/database_helper.dart';
import 'data/repositories/bill_repository_impl.dart';
import 'data/repositories/meter_reading_repository_impl.dart';
import 'data/repositories/meter_repository_impl.dart';
import 'domain/repositories/bill_repository.dart';
import 'domain/repositories/meter_reading_repository.dart';
import 'domain/repositories/meter_repository.dart';
import 'presentation/bloc/bill/bill_bloc.dart';
import 'presentation/bloc/meter/meter_bloc.dart';
import 'presentation/bloc/meter_reading/meter_reading_bloc.dart';
import 'presentation/bloc/theme/theme_bloc.dart';
import 'presentation/bloc/language/language_bloc.dart';
import 'presentation/bloc/currency/currency_bloc.dart';
import 'services/backup_service.dart';
import 'services/email_service.dart';
import 'services/notification_service.dart';
import 'services/pdf_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/currency_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies({required String currencyApiKey}) async {
  // Database
  getIt.registerLazySingleton(() => DatabaseHelper.instance);

  // Services
  getIt.registerLazySingleton(() => BackupService());
  getIt.registerLazySingleton(() => EmailService());
  getIt.registerLazySingleton(() => PdfService());
  getIt.registerLazySingleton(() => ThemeService());
  getIt.registerLazySingleton(() => NotificationService());

  // Initialize language and currency services
  await LanguageService.initialize();
  await CurrencyService.initialize();

  // Register language and currency services
  final languageService = LanguageService();
  final currencyService = CurrencyService(apiKey: currencyApiKey);
  await currencyService.loadExchangeRatesFromPrefs();

  getIt.registerLazySingleton<LanguageService>(() => languageService);
  getIt.registerLazySingleton<CurrencyService>(() => currencyService);

  // Repositories
  getIt.registerLazySingleton<MeterRepository>(
    () => MeterRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<MeterReadingRepository>(
    () => MeterReadingRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<BillRepository>(
    () => BillRepositoryImpl(getIt()),
  );

  // BLoCs
  getIt.registerFactory(
    () => MeterBloc(repository: getIt()),
  );

  getIt.registerFactory(
    () => MeterReadingBloc(repository: getIt()),
  );

  getIt.registerFactory(
    () => BillBloc(repository: getIt()),
  );

  getIt.registerFactory(
    () => ThemeBloc(),
  );

  getIt.registerFactory(
    () => LanguageBloc(getIt<LanguageService>()),
  );

  getIt.registerFactory(
    () => CurrencyBloc(getIt<CurrencyService>()),
  );
}
