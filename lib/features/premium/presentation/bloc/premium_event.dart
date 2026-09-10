part of 'premium_bloc.dart';

sealed class PremiumEvent extends Equatable {
  const PremiumEvent();

  @override
  List<Object?> get props => [];
}

class _PremiumStatusChanged extends PremiumEvent {
  const _PremiumStatusChanged(this.isPremium);

  final bool isPremium;

  @override
  List<Object?> get props => [isPremium];
}
