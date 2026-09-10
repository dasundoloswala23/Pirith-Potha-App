import 'package:equatable/equatable.dart';

/// Domain-level failure types. Data-layer exceptions (FirebaseException,
/// DioException, etc.) must be mapped into these before crossing into the
/// domain/presentation layers — see docs/02_architecture.md.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data is unavailable']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested item was not found']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
