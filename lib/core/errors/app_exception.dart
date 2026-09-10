import 'failure.dart';

/// Thrown by data sources/repositories once a raw platform error (Firebase,
/// Dio, etc.) has already been mapped to a domain [Failure] — see
/// docs/02_architecture.md. Presentation-layer code (BLoCs) catches this and
/// never needs to know about the underlying SDK exception type.
class AppException implements Exception {
  const AppException(this.failure);

  final Failure failure;

  @override
  String toString() => 'AppException(${failure.message})';
}
