import 'package:equatable/equatable.dart';

abstract class NewProjectEvent extends Equatable {
  const NewProjectEvent();

  @override
  List<Object> get props => [];
}

class UrlChanged extends NewProjectEvent {
  final String url;

  const UrlChanged(this.url);

  @override
  List<Object> get props => [url];
}

class ClipCountChanged extends NewProjectEvent {
  final int clipCount;

  const ClipCountChanged(this.clipCount);

  @override
  List<Object> get props => [clipCount];
}

class CreateProjectSubmitted extends NewProjectEvent {
  const CreateProjectSubmitted();
}
