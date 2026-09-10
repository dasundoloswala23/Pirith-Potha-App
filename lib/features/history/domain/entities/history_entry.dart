import 'package:equatable/equatable.dart';

class HistoryEntry extends Equatable {
  const HistoryEntry({required this.pirithId, required this.playedAt});

  final String pirithId;
  final DateTime playedAt;

  @override
  List<Object?> get props => [pirithId, playedAt];
}
