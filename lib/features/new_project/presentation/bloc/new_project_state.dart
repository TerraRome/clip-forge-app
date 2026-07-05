import 'package:equatable/equatable.dart';

abstract class NewProjectState extends Equatable {
  const NewProjectState();

  @override
  List<Object> get props => [];
}

class NewProjectInitial extends NewProjectState {
  const NewProjectInitial();
}

class NewProjectFormReady extends NewProjectState {
  final String url;
  final int clipCount;
  final bool isUrlValid;

  const NewProjectFormReady({
    this.url = '',
    this.clipCount = 3,
    this.isUrlValid = false,
  });

  @override
  List<Object> get props => [url, clipCount, isUrlValid];
}

class NewProjectLoading extends NewProjectState {
  const NewProjectLoading();
}

class NewProjectError extends NewProjectState {
  final String message;

  const NewProjectError(this.message);

  @override
  List<Object> get props => [message];
}

class NewProjectSuccess extends NewProjectState {
  final String projectId;

  const NewProjectSuccess(this.projectId);

  @override
  List<Object> get props => [projectId];
}
