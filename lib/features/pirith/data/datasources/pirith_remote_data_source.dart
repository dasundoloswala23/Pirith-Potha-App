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

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('sortOrder')
        .get();
    return snapshot.docs.map(CategoryModel.fromFirestore).toList();
  }

  @override
  Future<List<PirithModel>> getActivePirith() async {
    final snapshot = await _firestore
        .collection('pirith')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return snapshot.docs.map(PirithModel.fromFirestore).toList();
  }

  @override
  Future<PirithModel> getPirithById(String id) async {
    final doc = await _firestore.collection('pirith').doc(id).get();
    if (!doc.exists) throw const AppException(NotFoundFailure());
    return PirithModel.fromFirestore(doc);
  }
}
