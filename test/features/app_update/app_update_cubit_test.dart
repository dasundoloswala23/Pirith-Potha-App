import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/app_update/domain/entities/version_config.dart';
import 'package:pitithpotha/features/app_update/domain/repositories/version_config_repository.dart';
import 'package:pitithpotha/features/app_update/presentation/bloc/app_update_cubit.dart';

import '../../fakes/fake_version_config_repository.dart';

class _ThrowingRepository implements VersionConfigRepository {
  @override
  Future<VersionConfig?> getVersionConfig() => throw Exception('offline');
}

AppUpdateCubit _cubit({
  VersionConfigRepository? repository,
  String latest = '1.00.03',
  String Function()? installed,
  String? storeUrl = 'https://store/app',
}) => AppUpdateCubit(
  repository:
      repository ??
      FakeVersionConfigRepository(VersionConfig(latestVersion: latest)),
  installedVersion: () async => (installed ?? () => '1.00.03')(),
  storeUrl: () => storeUrl,
);

void main() {
  test('starts unknown', () {
    final cubit = _cubit();
    addTearDown(cubit.close);
    expect(cubit.state, isA<UpdateUnknown>());
  });

  test('current version: not required', () async {
    final cubit = _cubit();
    addTearDown(cubit.close);
    await cubit.check();
    expect(cubit.state, isA<UpdateNotRequired>());
  });

  test('newer patch: optional, shown once per launch', () async {
    final cubit = _cubit(latest: '1.00.04');
    addTearDown(cubit.close);
    await cubit.check();

    expect(cubit.state, isA<UpdateOptional>());
    expect(cubit.shouldShowOptional, isTrue);
    cubit.markOptionalShown();
    expect(cubit.shouldShowOptional, isFalse);

    await cubit.check();
    expect(cubit.state, isA<UpdateOptional>());
    expect(cubit.shouldShowOptional, isFalse, reason: 'session flag survives rechecks');
  });

  test('newer minor or major: mandatory', () async {
    for (final latest in ['1.01.00', '2.00.00']) {
      final cubit = _cubit(latest: latest);
      addTearDown(cubit.close);
      await cubit.check();
      expect(cubit.state, isA<UpdateMandatory>(), reason: latest);
      expect(cubit.shouldShowOptional, isFalse);
    }
  });

  test('offline / no config / throwing repository: fails open', () async {
    for (final repository in <VersionConfigRepository>[
      FakeVersionConfigRepository(),
      _ThrowingRepository(),
    ]) {
      final cubit = _cubit(repository: repository);
      addTearDown(cubit.close);
      await cubit.check();
      expect(cubit.state, isA<UpdateNotRequired>());
    }
  });

  test('no store to send the user to (iOS without an App Store id): '
      'never blocks, even for a major bump', () async {
    final cubit = _cubit(latest: '9.00.00', storeUrl: null);
    addTearDown(cubit.close);
    await cubit.check();
    expect(cubit.state, isA<UpdateNotRequired>());
  });

  test('platformStoreUrl: no App Store id yet means iOS has no store', () {
    // AppUrls.appStoreId is still empty in this repo.
    expect(AppUpdateCubit.platformStoreUrl(), anyOf(isNull, contains('play.google.com')));
  });

  test('recheck stays blocked until the installed version actually changes', () async {
    var installed = '1.00.03';
    final cubit = _cubit(latest: '1.01.00', installed: () => installed);
    addTearDown(cubit.close);

    await cubit.check();
    expect(cubit.state, isA<UpdateMandatory>());

    // Back from the store without updating.
    await cubit.recheck();
    expect(cubit.state, isA<UpdateMandatory>());

    installed = '1.01.00';
    await cubit.recheck();
    expect(cubit.state, isA<UpdateNotRequired>());
  });

  test('recheck does nothing unless blocked', () async {
    var reads = 0;
    final cubit = _cubit(installed: () {
      reads++;
      return '1.00.03';
    });
    addTearDown(cubit.close);
    await cubit.check();
    final before = reads;
    await cubit.recheck();
    expect(reads, before);
  });
}
