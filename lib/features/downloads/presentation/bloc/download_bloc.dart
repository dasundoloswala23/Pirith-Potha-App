import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/download_entity.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/usecases/cancel_download.dart';
import '../../domain/usecases/delete_download.dart';
import '../../domain/usecases/download_pirith.dart';

part 'download_event.dart';
part 'download_state.dart';

/// App-scoped BLoC (one instance for the whole app) so download status/
/// progress is consistent everywhere a Pirith is shown — see
/// docs/05_offline_download.md.
class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  DownloadBloc({
    required DownloadRepository downloadRepository,
    required DownloadPirith downloadPirith,
    required CancelDownload cancelDownload,
    required DeleteDownload deleteDownload,
  })  : _downloadRepository = downloadRepository,
        _downloadPirith = downloadPirith,
        _cancelDownload = cancelDownload,
        _deleteDownload = deleteDownload,
        super(const DownloadsLoading()) {
    on<DownloadRequested>((event, emit) => _downloadPirith(event.item));
    on<DownloadCancelRequested>((event, emit) => _cancelDownload(event.pirithId));
    on<DownloadDeleteRequested>((event, emit) => _deleteDownload(event.pirithId));
    on<_DownloadsChanged>((event, emit) => emit(DownloadsLoaded(event.downloads)));

    add(_DownloadsChanged(_downloadRepository.currentDownloads));
    _subscription = _downloadRepository.downloadsStream.listen(
      (downloads) => add(_DownloadsChanged(downloads)),
    );
  }

  final DownloadRepository _downloadRepository;
  final DownloadPirith _downloadPirith;
  final CancelDownload _cancelDownload;
  final DeleteDownload _deleteDownload;

  late final StreamSubscription<Map<String, DownloadEntity>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
