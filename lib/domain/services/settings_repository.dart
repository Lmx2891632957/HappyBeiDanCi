import '../models/app_settings.dart';

/// 设置仓储契约（settings 键值表）。
abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);

  Future<String?> get(String key);

  Future<void> set(String key, String value);
}
