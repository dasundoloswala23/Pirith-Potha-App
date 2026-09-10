import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/premium/domain/entities/premium_feature.dart';
import 'package:pitithpotha/features/premium/presentation/bloc/premium_bloc.dart';

import '../../fakes/fake_premium_repository.dart';

void main() {
  group('PremiumBloc', () {
    test('starts with the repository\'s current status', () {
      final repository = FakePremiumRepository(isPremium: true);
      final bloc = PremiumBloc(premiumRepository: repository);
      addTearDown(bloc.close);

      expect(bloc.state.isPremium, isTrue);
      expect(bloc.state.hasAccess(PremiumFeature.premiumContent), isTrue);
    });

    test('reflects entitlement changes from the repository stream', () async {
      final repository = FakePremiumRepository();
      final bloc = PremiumBloc(premiumRepository: repository);
      addTearDown(bloc.close);

      expect(bloc.state.isPremium, isFalse);

      final future = expectLater(
        bloc.stream,
        emits(isA<PremiumState>().having((s) => s.isPremium, 'isPremium', isTrue)),
      );
      repository.setPremium(true);
      await future;
    });
  });
}
