import 'package:equatable/equatable.dart';

/// Domain-level user, decoupled from `firebase_auth`'s `User` type so
/// presentation/domain code never imports Firebase directly — see
/// docs/02_architecture.md.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  @override
  List<Object?> get props => [uid, isAnonymous, displayName, email, photoUrl];
}
