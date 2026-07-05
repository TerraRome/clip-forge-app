import 'package:equatable/equatable.dart';

/// Events for [HomeBloc].
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Load projects from local storage.
class LoadProjects extends HomeEvent {
  const LoadProjects();
}
