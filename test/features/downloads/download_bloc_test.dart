import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/downloads/domain/entities/download_entity.dart';
import 'package:pitithpotha/features/downloads/domain/usecases/cancel_download.dart';
import 'package:pitithpotha/features/downloads/domain/usecases/delete_download.dart';
import 'package:pitithpotha/features/downloads/domain/usecases/download_pirith.dart';
import 'package:pitithpotha/features/downloads/presentation/bloc/download_bloc.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';

import '../../fakes/fake_download_repository.dart';

const _item = PirithEntity(
  id: '1',
  title: 'Ratana Sutta',
  titleSinhala: 'රතන සූත්‍රය',
  description: '',
  descriptionSinhala: '',
  coverUrl: '',
  audioUrl: 'https://example.com/audio.mp3',
  duration: 1102,
  categoryId: 'protective',
  isPremium: false,
  isFeatured: false,
  sortOrder: 1,
  playCount: 0,
  downloadCount: 0,
);

DownloadBloc _buildBloc(FakeDownloadRepository repository) => DownloadBloc(
      downloadRepository: repository,
      downloadPirith: DownloadPirith(repository),
      cancelDownload: CancelDownload(repository),
      deleteDownload: DeleteDownload(repository),
    );

void main() {
  group('DownloadBloc', () {
    test('starts with an empty loaded state', () async {
      final repository = FakeDownloadRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final state = bloc.state as DownloadsLoaded;
      expect(state.downloads, isEmpty);
    });

    test('download adds a downloaded entry', () async {
      final repository = FakeDownloadRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      final future = expectLater(
        bloc.stream,
        emitsThrough(
          isA<DownloadsLoaded>().having(
            (s) => s.statusFor('1')?.status,
            'status',
            DownloadStatus.downloaded,
          ),
        ),
      );
      bloc.add(const DownloadRequested(_item));
      await future;
    });

    test('delete removes the entry', () async {
      final repository = FakeDownloadRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const DownloadRequested(_item));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emits(isA<DownloadsLoaded>().having((s) => s.downloads, 'downloads', isEmpty)),
      );
      bloc.add(const DownloadDeleteRequested('1'));
      await future;
    });
  });
}
