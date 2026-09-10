import 'dart:async';

import 'package:pitithpotha/features/downloads/domain/entities/download_entity.dart';
import 'package:pitithpotha/features/downloads/domain/repositories/download_repository.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';

/// In-memory [DownloadRepository] fake for widget/BLoC tests, so tests
/// don't need real file system / network access to exercise
/// [DownloadBloc].
class FakeDownloadRepository implements DownloadRepository {
  final _downloads = <String, DownloadEntity>{};
  final _controller = StreamController<Map<String, DownloadEntity>>.broadcast();

  @override
  Stream<Map<String, DownloadEntity>> get downloadsStream => _controller.stream;

  @override
  Map<String, DownloadEntity> get currentDownloads => Map.unmodifiable(_downloads);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> download(PirithEntity item) async {
    _downloads[item.id] = DownloadEntity(
      pirithId: item.id,
      status: DownloadStatus.downloaded,
      progress: 1,
      localAudioPath: '/fake/${item.id}/audio.mp3',
    );
    _controller.add(Map.unmodifiable(_downloads));
  }

  @override
  Future<void> cancelDownload(String pirithId) async {
    _downloads.remove(pirithId);
    _controller.add(Map.unmodifiable(_downloads));
  }

  @override
  Future<void> deleteDownload(String pirithId) async {
    _downloads.remove(pirithId);
    _controller.add(Map.unmodifiable(_downloads));
  }

  @override
  String? localAudioPathFor(String pirithId) => _downloads[pirithId]?.localAudioPath;
}
