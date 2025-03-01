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
import 'services/backup_service.dart';
import 'services/email_service.dart';
import 'services/notification_service.dart';
import 'services/pdf_service.dart';
import 'services/theme_service.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Database
  getIt.registerLazySingleton(() => DatabaseHelper.instance);

  // Services
  getIt.registerLazySingleton(() => BackupService());
  getIt.registerLazySingleton(() => EmailService());
  getIt.registerLazySingleton(() => PdfService());
  getIt.registerLazySingleton(() => ThemeService());
  getIt.registerLazySingleton(() => NotificationService());

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
}
