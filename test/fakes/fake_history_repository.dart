import 'dart:async';

import 'package:pitithpotha/features/history/domain/entities/history_entry.dart';
import 'package:pitithpotha/features/history/domain/repositories/history_repository.dart';

/// In-memory [HistoryRepository] fake for widget/BLoC tests.
class FakeHistoryRepository implements HistoryRepository {
  List<HistoryEntry> _entries = [];
  final _controller = StreamController<List<HistoryEntry>>.broadcast();

  @override
  Stream<List<HistoryEntry>> get historyStream => _controller.stream;

  @override
  List<HistoryEntry> get currentHistory => List.unmodifiable(_entries);

  @override
  Future<void> recordPlayed(String pirithId) async {
    _entries = [
      HistoryEntry(pirithId: pirithId, playedAt: DateTime.now()),
      ..._entries.where((e) => e.pirithId != pirithId),
    ];
    _controller.add(List.unmodifiable(_entries));
  }
}
