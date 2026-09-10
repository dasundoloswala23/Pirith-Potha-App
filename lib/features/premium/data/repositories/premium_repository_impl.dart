import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/premium_feature.dart';
import '../../domain/repositories/premium_repository.dart';

/// Watches `users/{uid}.isPremium` for whichever uid [AuthRepository]
/// currently reports (guest or signed-in — see the interface doc comment
/// for why this is a development placeholder, not real entitlement).
class PremiumRepositoryImpl implements PremiumRepository {
  PremiumRepositoryImpl({
    required FirebaseFirestore firestore,
    required AuthRepository authRepository,
  })  : _firestore = firestore,
        _authRepository = authRepository {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      _watchUid(user?.uid);
    });
    _watchUid(_authRepository.currentUser?.uid);
  }

  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<dynamic>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSubscription;
  bool _isPremium = false;

  @override
  Stream<bool> get isPremiumStream => _controller.stream;

  @override
  bool get isPremium => _isPremium;

  @override
  bool hasAccess(PremiumFeature feature) => _isPremium;

  void _watchUid(String? uid) {
    _docSubscription?.cancel();
    if (uid == null) {
      _update(false);
      return;
    }
    _docSubscription = _firestore.collection('users').doc(uid).snapshots().listen(
      (doc) => _update((doc.data()?['isPremium'] as bool?) ?? false),
      onError: (_) => _update(false),
    );
  }

  void _update(bool value) {
    _isPremium = value;
    _controller.add(value);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _docSubscription?.cancel();
    await _controller.close();
  }
}
