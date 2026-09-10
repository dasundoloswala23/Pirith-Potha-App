import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._prefs);

  static const _key = 'pirith_history';
  static const _maxEntries = 50;
  static const _separator = '::';

  final SharedPreferences _prefs;
  final _controller = StreamController<List<HistoryEntry>>.broadcast();

  List<HistoryEntry> _entries = [];

  Future<void> initialize() async {
    final raw = _prefs.getStringList(_key) ?? [];
    _entries = raw.map(_decode).whereType<HistoryEntry>().toList();
  }

  @override
  Stream<List<HistoryEntry>> get historyStream => _controller.stream;

  @override
  List<HistoryEntry> get currentHistory => List.unmodifiable(_entries);

  @override
  Future<void> recordPlayed(String pirithId) async {
    final withoutExisting = _entries.where((e) => e.pirithId != pirithId).toList();
    final updated = [HistoryEntry(pirithId: pirithId, playedAt: DateTime.now()), ...withoutExisting];
    _entries = updated.take(_maxEntries).toList();
    await _prefs.setStringList(_key, _entries.map(_encode).toList());
    _controller.add(List.unmodifiable(_entries));
  }

  String _encode(HistoryEntry entry) =>
      '${entry.pirithId}$_separator${entry.playedAt.millisecondsSinceEpoch}';

  HistoryEntry? _decode(String raw) {
    final parts = raw.split(_separator);
    if (parts.length != 2) return null;
    final millis = int.tryParse(parts[1]);
    if (millis == null) return null;
    return HistoryEntry(
      pirithId: parts[0],
      playedAt: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}
