import 'package:equatable/equatable.dart';
import '../../../../domain/entities/project.dart';

/// States for [HomeBloc].
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded yet.
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading projects from local storage.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Projects loaded successfully.
class HomeLoaded extends HomeState {
  final List<Project> projects;

  const HomeLoaded({required this.projects});

  @override
  List<Object?> get props => [projects];
}

/// Error loading projects.
class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
