import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/download_entity.dart';
import '../../domain/repositories/download_repository.dart';

/// Owns the Dio transfer, local file system, and per-item status — this
/// *is* the "DownloadManager" from docs/05_offline_download.md; there's
/// only one implementation, so no extra indirection on top of it.
///
/// Layout on disk (see docs/03_database_schema.md):
/// ```
/// ApplicationDocuments/pirith/{pirithId}/audio.mp3
/// ```
/// A downloaded Pirith is playable with zero network calls — see
/// [localAudioPathFor] and how `AudioRepositoryImpl` consults it.
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(this._dio);

  final Dio _dio;

  final _downloads = <String, DownloadEntity>{};
  final _cancelTokens = <String, CancelToken>{};
  final _controller = StreamController<Map<String, DownloadEntity>>.broadcast();

  @override
  Stream<Map<String, DownloadEntity>> get downloadsStream => _controller.stream;

  @override
  Map<String, DownloadEntity> get currentDownloads => Map.unmodifiable(_downloads);

  @override
  Future<void> initialize() async {
    final root = await _pirithRootDir();
    if (!root.existsSync()) return;

    for (final entry in root.listSync()) {
      if (entry is! Directory) continue;
      final pirithId = entry.path.split(Platform.pathSeparator).last;
      final audioFile = File('${entry.path}/audio.mp3');
      if (audioFile.existsSync()) {
        _downloads[pirithId] = DownloadEntity(
          pirithId: pirithId,
          status: DownloadStatus.downloaded,
          progress: 1,
          localAudioPath: audioFile.path,
        );
      }
    }
    _emit();
  }

  @override
  Future<void> download(PirithEntity item) async {
    // Before the directory is created and before the `downloading` entry is
    // published: without this an empty URL left a stray empty folder and a
    // Retry button that could never succeed.
    if (!item.hasAudio) return;

    final existing = _downloads[item.id];
    if (existing?.status == DownloadStatus.downloading ||
        existing?.status == DownloadStatus.downloaded) {
      return; // No duplicate downloads.
    }

    final dir = await _pirithItemDir(item.id);
    await dir.create(recursive: true);
    final audioPath = '${dir.path}/audio.mp3';
    final tempPath = '$audioPath.part';

    _update(DownloadEntity(pirithId: item.id, status: DownloadStatus.downloading));

    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      await _dio.download(
        item.audioUrl,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          _update(
            (_downloads[item.id] ?? DownloadEntity(pirithId: item.id, status: DownloadStatus.downloading))
                .copyWith(progress: received / total),
          );
        },
      );
      await File(tempPath).rename(audioPath);
      _update(
        DownloadEntity(
          pirithId: item.id,
          status: DownloadStatus.downloaded,
          progress: 1,
          localAudioPath: audioPath,
        ),
      );
    } on DioException catch (e) {
      await _cleanupPartial(tempPath);
      if (e.type == DioExceptionType.cancel) {
        _downloads.remove(item.id);
        _emit();
      } else {
        _update(DownloadEntity(pirithId: item.id, status: DownloadStatus.failed));
      }
    } catch (_) {
      await _cleanupPartial(tempPath);
      _update(DownloadEntity(pirithId: item.id, status: DownloadStatus.failed));
    } finally {
      _cancelTokens.remove(item.id);
    }
  }

  @override
  Future<void> cancelDownload(String pirithId) async {
    _cancelTokens[pirithId]?.cancel();
  }

  @override
  Future<void> deleteDownload(String pirithId) async {
    _cancelTokens[pirithId]?.cancel();
    final dir = await _pirithItemDir(pirithId);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    _downloads.remove(pirithId);
    _emit();
  }

  @override
  String? localAudioPathFor(String pirithId) {
    final entry = _downloads[pirithId];
    if (entry?.status != DownloadStatus.downloaded) return null;
    final path = entry!.localAudioPath;
    if (path == null) return null;
    if (!File(path).existsSync()) {
      // Referenced in memory but missing on disk (e.g. cleared by the OS) —
      // self-heal rather than surface a playback error.
      _downloads.remove(pirithId);
      _emit();
      return null;
    }
    return path;
  }

  Future<Directory> _pirithRootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/pirith');
  }

  Future<Directory> _pirithItemDir(String pirithId) async {
    final root = await _pirithRootDir();
    return Directory('${root.path}/$pirithId');
  }

  Future<void> _cleanupPartial(String tempPath) async {
    final file = File(tempPath);
    if (file.existsSync()) {
      try {
        await file.delete();
      } catch (_) {
        // Best-effort cleanup; a stray .part file doesn't break anything.
      }
    }
  }

  void _update(DownloadEntity entity) {
    _downloads[entity.pirithId] = entity;
    _emit();
  }

  void _emit() => _controller.add(Map.unmodifiable(_downloads));
}
