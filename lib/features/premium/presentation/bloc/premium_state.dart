part of 'premium_bloc.dart';

class PremiumState extends Equatable {
  const PremiumState({required this.isPremium});

  final bool isPremium;

  bool hasAccess(PremiumFeature feature) => isPremium;

  @override
  List<Object?> get props => [isPremium];
}
