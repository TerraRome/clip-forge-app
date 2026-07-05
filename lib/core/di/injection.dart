import 'package:get_it/get_it.dart';
import 'package:klip_mobile/features/home/data/datasources/home_local_datasource.dart';
import 'package:klip_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:klip_mobile/features/home/presentation/bloc/home_bloc.dart';
import 'package:klip_mobile/features/new_project/presentation/bloc/new_project_bloc.dart';
import 'package:klip_mobile/features/processing/presentation/bloc/processing_bloc.dart';
import 'package:klip_mobile/features/results/presentation/bloc/results_bloc.dart';
import 'package:klip_mobile/domain/repositories/project_repository.dart';

/// Service locator instance.
final sl = GetIt.instance;

/// Set up dependency injection.
Future<void> setupLocator() async {
  // Data sources
  sl.registerLazySingleton<HomeLocalDatasource>(
    () => HomeLocalDatasourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<ProjectRepository>(
    () => HomeRepositoryImpl(localDatasource: sl()),
  );

  // Blocs
  sl.registerFactory(() => HomeBloc(projectRepository: sl()));
  sl.registerFactory(() => NewProjectBloc(repository: sl()));
  sl.registerFactory(() => ProcessingBloc(repository: sl()));
  sl.registerFactory(() => ResultsBloc(repository: sl()));
}
