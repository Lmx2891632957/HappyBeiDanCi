/// Settings 仓储集成测试：缺键默认值回填、批量保存、单键读写、损坏值拒绝
///（TECH_DOC §8.1 settings / §18 默认值，AGENTS §7）。
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/core/constants.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_settings_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/app_settings.dart';
import 'package:happy_bei_dan_ci/domain/services/settings_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_settings_repo',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, SettingsRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftSettingsRepository(db));
  }

  test('空表 load：全部缺键回填默认值（§18）并返回默认设置', () async {
    final (db, repo) = openRepo('empty_defaults');
    final settings = await repo.load();
    expect(settings.dailyNewWords, AppConstants.defaultDailyNewWords);
    expect(settings.reviewCap, AppConstants.defaultReviewCap);
    expect(settings.reminderEnabled, isTrue);
    expect(settings.reminderTime, AppConstants.defaultReminderTime);
    expect(settings.examDate, isNull);
    expect(settings.timezone, AppConstants.defaultTimezone);
    expect(settings.onboardingDone, isFalse);

    // 回填已落库：全部键都存在。
    final rows = await db.select(db.settings).get();
    expect({for (final r in rows) r.key}, AppSettingKeys.all.toSet());
    final reviewRow = rows.singleWhere(
      (r) => r.key == AppSettingKeys.reviewCap,
    );
    expect(reviewRow.value, AppConstants.defaultReviewCap.toString());
    final examRow = rows.singleWhere((r) => r.key == AppSettingKeys.examDate);
    expect(examRow.value, isEmpty);
    final onboardingRow = rows.singleWhere(
      (r) => r.key == AppSettingKeys.onboardingDone,
    );
    expect(onboardingRow.value, 'false');
  });

  test('首启标记与每日目标：save(onboardingDone: true) → load 往返', () async {
    final (_, repo) = openRepo('onboarding_flag');
    await repo.save(const AppSettings(dailyNewWords: 30, onboardingDone: true));
    final loaded = await repo.load();
    expect(loaded.onboardingDone, isTrue);
    expect(loaded.dailyNewWords, 30);
    expect(await repo.get(AppSettingKeys.onboardingDone), 'true');

    // 未完成引导的默认口径：标记为 false。
    await repo.save(const AppSettings(onboardingDone: false));
    final reloaded = await repo.load();
    expect(reloaded.onboardingDone, isFalse);
  });

  test('save→load 往返：全部字段逐项一致', () async {
    final (db, repo) = openRepo('roundtrip');
    final exam = DateTime(2026, 6, 7, 9);
    await repo.save(
      AppSettings(
        dailyNewWords: 30,
        reviewCap: null,
        reminderEnabled: false,
        reminderTime: '21:30',
        examDate: exam,
        timezone: 'Asia/Shanghai',
        wordbookVersion: '1.0',
      ),
    );
    final loaded = await repo.load();
    expect(loaded.dailyNewWords, 30);
    expect(loaded.reviewCap, isNull);
    expect(loaded.reminderEnabled, isFalse);
    expect(loaded.reminderTime, '21:30');
    expect(loaded.examDate, exam);
    expect(loaded.timezone, 'Asia/Shanghai');
    expect(loaded.wordbookVersion, '1.0');

    // 存储层校验：reviewCap 关闭存 'off'、examDate 存 epoch 毫秒文本。
    final rows = await db.select(db.settings).get();
    expect(
      rows.singleWhere((r) => r.key == AppSettingKeys.reviewCap).value,
      'off',
    );
    expect(
      rows.singleWhere((r) => r.key == AppSettingKeys.examDate).value,
      exam.millisecondsSinceEpoch.toString(),
    );
  });

  test('save 覆盖更新整行，不残留旧键', () async {
    final (db, repo) = openRepo('overwrite');
    await repo.save(const AppSettings(dailyNewWords: 10, reviewCap: 50));
    await repo.save(const AppSettings(dailyNewWords: 20, reviewCap: 300));
    final loaded = await repo.load();
    expect(loaded.dailyNewWords, 20);
    expect(loaded.reviewCap, 300);
    expect(
      await db.select(db.settings).get(),
      hasLength(AppSettingKeys.all.length),
    );
  });

  test('get/set 单键读写；get 缺失返回 null', () async {
    final (_, repo) = openRepo('single_key');
    expect(await repo.get(AppSettingKeys.dailyNewWords), isNull);
    await repo.set(AppSettingKeys.dailyNewWords, '50');
    expect(await repo.get(AppSettingKeys.dailyNewWords), '50');
  });

  test('部分缺键 load：缺失键回填、既有键保留', () async {
    final (db, repo) = openRepo('partial');
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            key: AppSettingKeys.dailyNewWords,
            value: '50',
          ),
        );
    final loaded = await repo.load();
    expect(loaded.dailyNewWords, 50);
    expect(loaded.reviewCap, AppConstants.defaultReviewCap);
    expect(
      await repo.get(AppSettingKeys.reviewCap),
      AppConstants.defaultReviewCap.toString(),
    );
  });

  group('损坏值口径：抛 StateError，不静默', () {
    Future<void> seedRaw(AppDatabase db, String key, String value) {
      return db
          .into(db.settings)
          .insert(SettingsCompanion.insert(key: key, value: value));
    }

    test('daily_new_words 非整数', () async {
      final (db, repo) = openRepo('bad_int');
      await seedRaw(db, AppSettingKeys.dailyNewWords, 'abc');
      await expectLater(repo.load(), throwsA(isA<StateError>()));
    });

    test('reminder_enabled 非布尔', () async {
      final (db, repo) = openRepo('bad_bool');
      await seedRaw(db, AppSettingKeys.reminderEnabled, 'yes');
      await expectLater(repo.load(), throwsA(isA<StateError>()));
    });

    test('review_cap 负数拒绝', () async {
      final (db, repo) = openRepo('bad_cap');
      await seedRaw(db, AppSettingKeys.reviewCap, '-5');
      await expectLater(repo.load(), throwsA(isA<StateError>()));
    });

    test('exam_date 非 epoch 毫秒', () async {
      final (db, repo) = openRepo('bad_date');
      await seedRaw(db, AppSettingKeys.examDate, 'tomorrow');
      await expectLater(repo.load(), throwsA(isA<StateError>()));
    });
  });
}
