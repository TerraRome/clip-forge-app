/// Base failure class for the application.
/// Used throughout the data layer to represent errors.
/// ponytail: add sealed subclasses for specific error types when error handling grows.
sealed class Failure {
  const Failure(this.message, [this.code]);

  final String message;
  final String? code;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class ProcessingFailure extends Failure {
  const ProcessingFailure(super.message, [super.code]);
}
