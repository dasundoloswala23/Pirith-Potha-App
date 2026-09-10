import 'dart:async';

import 'package:pitithpotha/features/premium/domain/entities/premium_feature.dart';
import 'package:pitithpotha/features/premium/domain/repositories/premium_repository.dart';

/// In-memory [PremiumRepository] fake for widget/BLoC tests.
class FakePremiumRepository implements PremiumRepository {
  FakePremiumRepository({bool isPremium = false}) : _isPremium = isPremium;

  bool _isPremium;
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get isPremiumStream => _controller.stream;

  @override
  bool get isPremium => _isPremium;

  @override
  bool hasAccess(PremiumFeature feature) => _isPremium;

  void setPremium(bool value) {
    _isPremium = value;
    _controller.add(value);
  }
}
