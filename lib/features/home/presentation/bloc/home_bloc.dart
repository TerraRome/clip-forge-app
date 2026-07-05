import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../../domain/repositories/project_repository.dart';
import '../../../../core/errors/exceptions.dart';

/// Business logic for the Home screen.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProjectRepository _projectRepository;

  HomeBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(const HomeInitial()) {
    on<LoadProjects>(_onLoadProjects);
  }

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final projects = await _projectRepository.getRecentProjects();
      emit(HomeLoaded(projects: projects));
    } on AppException catch (e) {
      emit(HomeError(message: e.message));
    } catch (e) {
      emit(HomeError(message: 'Failed to load projects: $e'));
    }
  }
}
