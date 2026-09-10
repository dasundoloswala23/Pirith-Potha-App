import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../models/category_model.dart';
import '../models/pirith_model.dart';

abstract interface class PirithRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<PirithModel>> getActivePirith();
  Future<PirithModel> getPirithById(String id);
}

class FirestorePirithRemoteDataSource implements PirithRemoteDataSource {
  FirestorePirithRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  /// Server-only: when Firestore can't reach the backend it resolves reads
  /// from its own (empty) offline cache *without throwing*, which makes an
  /// unreachable backend look identical to "no content published yet". This
  /// app keeps its own on-disk cache in PirithLocalDataSource, so it wants
  /// the failure instead — PirithRepositoryImpl turns that into a cache
  /// fallback, or a retryable error when there's nothing cached.
  static const _serverOnly = GetOptions(source: Source.server);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .get(_serverOnly);
    return snapshot.docs.map(CategoryModel.fromFirestore).toList();
  }

  @override
  Future<List<PirithModel>> getActivePirith() async {
    final snapshot = await _firestore
        .collection('pirith')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get(_serverOnly);
    return snapshot.docs.map(PirithModel.fromFirestore).toList();
  }

  @override
  Future<PirithModel> getPirithById(String id) async {
    final doc = await _firestore.collection('pirith').doc(id).get();
    if (!doc.exists) throw const AppException(NotFoundFailure());
    return PirithModel.fromFirestore(doc);
  }
}
