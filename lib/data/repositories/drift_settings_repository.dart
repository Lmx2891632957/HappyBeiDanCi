import '../../core/constants.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/services/settings_repository.dart';
import '../local/app_database.dart';

/// 设置仓储实现（Drift，TECH_DOC §8.1 settings 通用键值表）。
///
/// 序列化口径：整数/布尔以可读文本存储；`reviewCap = null`（关闭）存 `'off'`；
/// `examDate` 存 epoch 毫秒文本、空串表示未设置（§7.5 时间口径）。
/// 缺失键在 [load] 时按 `AppSettings` 默认值（TECH_DOC §18）回填写入，
/// 使默认值只维护在领域模型与常量中、不散落于存储层。
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  /// 复习软上限“关闭”的存储值（null 的文本表示）。
  static const String _reviewCapOff = 'off';

  @override
  Future<AppSettings> load() async {
    final rows = await _db.select(_db.settings).get();
    final values = {for (final row in rows) row.key: row.value};
    final defaults = const AppSettings();

    final settings = AppSettings(
      dailyNewWords: _readInt(
        values,
        AppSettingKeys.dailyNewWords,
        defaults.dailyNewWords,
      ),
      reviewCap: _readReviewCap(values, defaults.reviewCap),
      reminderEnabled: _readBool(
        values,
        AppSettingKeys.reminderEnabled,
        defaults.reminderEnabled,
      ),
      reminderTime:
          values[AppSettingKeys.reminderTime] ?? defaults.reminderTime,
      examDate: _readExamDate(values, defaults.examDate),
      timezone: values[AppSettingKeys.timezone] ?? defaults.timezone,
      onboardingDone: _readBool(
        values,
        AppSettingKeys.onboardingDone,
        defaults.onboardingDone,
      ),
      // 空串按未安装处理（与 _toMap 写入口径一致）。
      wordbookVersion: _readNullableText(
        values,
        AppSettingKeys.wordbookVersion,
        defaults.wordbookVersion,
      ),
      pronunciationEnabled: _readBool(
        values,
        AppSettingKeys.pronunciationEnabled,
        defaults.pronunciationEnabled,
      ),
      audioDownloadOnCellular: _readBool(
        values,
        AppSettingKeys.audioDownloadOnCellular,
        defaults.audioDownloadOnCellular,
      ),
    );

    // 缺失键回填默认值：settings 为通用键值表，缺键按默认值补齐，
    // 避免后续 get/set 单键读到时再次缺失（口径：load 对缺失键回填）。
    final encoded = _toMap(settings);
    final missing = {
      for (final key in AppSettingKeys.all)
        if (!values.containsKey(key)) key: encoded[key]!,
    };
    if (missing.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(_db.settings, [
          for (final entry in missing.entries)
            SettingsCompanion.insert(key: entry.key, value: entry.value),
        ]);
      });
    }
    return settings;
  }

  @override
  Future<void> save(AppSettings settings) {
    final encoded = _toMap(settings);
    // 单写连接批量 upsert（§8.2）：一次保存全量键，避免部分更新残留旧值。
    return _db.transaction(() async {
      for (final entry in encoded.entries) {
        await _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              SettingsCompanion.insert(key: entry.key, value: entry.value),
            );
      }
    });
  }

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Map<String, String> _toMap(AppSettings settings) => {
    AppSettingKeys.dailyNewWords: settings.dailyNewWords.toString(),
    AppSettingKeys.reviewCap: settings.reviewCap?.toString() ?? _reviewCapOff,
    AppSettingKeys.reminderEnabled: settings.reminderEnabled ? 'true' : 'false',
    AppSettingKeys.reminderTime: settings.reminderTime,
    AppSettingKeys.examDate:
        settings.examDate?.millisecondsSinceEpoch.toString() ?? '',
    AppSettingKeys.timezone: settings.timezone,
    AppSettingKeys.onboardingDone: settings.onboardingDone ? 'true' : 'false',
    AppSettingKeys.wordbookVersion: settings.wordbookVersion ?? '',
    AppSettingKeys.pronunciationEnabled:
        settings.pronunciationEnabled ? 'true' : 'false',
    AppSettingKeys.audioDownloadOnCellular:
        settings.audioDownloadOnCellular ? 'true' : 'false',
  };

  /// 读取可空文本键：缺失/空串 → null（未设置）。
  String? _readNullableText(
    Map<String, String> values,
    String key,
    String? fallback,
  ) {
    final raw = values[key];
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    return raw;
  }

  /// 读取整数键；缺失用默认值，坏值抛 StateError（与既有仓储"损坏不静默"
  /// 口径一致，避免静默改写设置）。
  int _readInt(Map<String, String> values, String key, int fallback) {
    final raw = values[key];
    if (raw == null) {
      return fallback;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      throw StateError('settings 损坏：$key 不是整数（value=$raw）');
    }
    return parsed;
  }

  int? _readReviewCap(Map<String, String> values, int? fallback) {
    final raw = values[AppSettingKeys.reviewCap];
    if (raw == null) {
      return fallback;
    }
    if (raw == _reviewCapOff) {
      return null;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      throw StateError(
        'settings 损坏：${AppSettingKeys.reviewCap} 非法（value=$raw）',
      );
    }
    return parsed;
  }

  bool _readBool(Map<String, String> values, String key, bool fallback) {
    final raw = values[key];
    if (raw == null) {
      return fallback;
    }
    return switch (raw) {
      'true' => true,
      'false' => false,
      _ => throw StateError('settings 损坏：$key 不是布尔（value=$raw）'),
    };
  }

  /// 读取可空文本键：缺失/空串 → null（未设置）。
  String? _readNullableText(
    Map<String, String> values,
    String key,
    String? fallback,
  ) {
    final raw = values[key];
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    return raw;
  }

  DateTime? _readExamDate(Map<String, String> values, DateTime? fallback) {
    final raw = values[AppSettingKeys.examDate];
    if (raw == null) {
      return fallback;
    }
    if (raw.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      throw StateError(
        'settings 损坏：${AppSettingKeys.examDate} 不是 epoch 毫秒（value=$raw）',
      );
    }
    return DateTime.fromMillisecondsSinceEpoch(parsed);
  }
}
