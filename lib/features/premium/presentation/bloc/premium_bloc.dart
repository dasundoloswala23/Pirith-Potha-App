import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/premium_feature.dart';
import '../../domain/repositories/premium_repository.dart';

part 'premium_event.dart';
part 'premium_state.dart';

/// App-scoped BLoC (one instance for the whole app) mirroring
/// [PremiumRepository]'s entitlement stream — see
/// docs/07_monetization.md. Screens read `state.hasAccess(feature)`
/// rather than reaching into the repository directly.
class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  PremiumBloc({required PremiumRepository premiumRepository})
      : _premiumRepository = premiumRepository,
        super(PremiumState(isPremium: premiumRepository.isPremium)) {
    on<_PremiumStatusChanged>(
      (event, emit) => emit(PremiumState(isPremium: event.isPremium)),
    );
    _subscription = _premiumRepository.isPremiumStream.listen(
      (isPremium) => add(_PremiumStatusChanged(isPremium)),
    );
  }

  final PremiumRepository _premiumRepository;

  late final StreamSubscription<bool> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
