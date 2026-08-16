import 'package:workmanager/workmanager.dart';

import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../domain/models/audio_pack.dart';
import '../local/app_database.dart';
import '../repositories/drift_audio_pack_repository.dart';
import '../repositories/drift_wordbook_repository.dart';
import 'audio_pack_downloader.dart';
import 'audio_pack_paths.dart';

/// WorkManager 后台回调入口（TECH_DOC §11.2）：Android 独立 isolate 中执行，
/// 与 UI 隔离；任务参数（wordbookId/version）由 [AudioPackDownloadScheduler]
/// 写入。系统停止任务时经 onTaskStopped 置取消标记，下载器按分块中止。
@pragma('vm:entry-point')
void audioPackCallbackDispatcher() {
  var stopped = false;
  Workmanager().executeTask(
    (taskName, inputData) => _runAudioPackTask(
      inputData,
      isCancelled: () => stopped,
    ),
    onTaskStopped: (taskName, stopReason) async {
      stopped = true;
    },
  );
}

/// 单次下载任务执行体：拉取 manifest → 校验目标一致 → 状态置 downloading →
/// Range 续传（进度写 audio_packs.downloaded_size）→ zip 校验/原子替换 →
/// 置 ready。返回 true 表示成功（WorkManager 不再重试），false 走指数退避。
///
/// 失败语义（TECH_DOC §9.2/§9.3）：网络/解压失败保留 downloading 状态与
/// .part（下次续传）；SHA-256 校验失败回退 not_downloaded（.part 已被下载器
/// 删除，需整包重下）；任务被系统停止按 cancelled 处理、不落失败标记。
Future<bool> _runAudioPackTask(
  Map<String, dynamic>? inputData, {
  required bool Function() isCancelled,
}) async {
  final wordbookId = inputData?['wordbookId'] as int?;
  final version = inputData?['version'] as String?;
  if (wordbookId == null || version == null || version.isEmpty) {
    AppLogger.error('音频包任务缺少参数：$inputData');
    return false;
  }

  final db = AppDatabase();
  try {
    final packs = DriftAudioPackRepository(db);
    // TD-14 内容全内置：内置词书（level=gaokao）发音随 APK 打包，不下载。
    // 兜底旧版本遗留/手动排队的任务（调度侧已按词书跳过，§9.2 触发）。
    final book = await DriftWordbookRepository(db).getWordbookById(wordbookId);
    if (AppConstants.isBuiltInWordbookLevel(book?.level)) {
      return true;
    }
    final pack = await packs.get(wordbookId);
    if (pack?.status == AudioPackStatus.ready && pack!.version == version) {
      return true; // 已就绪：幂等成功。
    }

    final downloader = AudioPackDownloader(
      packRootProvider: (_) => AudioPackPaths.packRoot(wordbookId),
    );
    final baseUri = Uri.parse(
      AppConstants.audioPackReleaseBaseUrl(
        AppConstants.defaultWordbookPackBase,
        version,
      ),
    );
    final manifest = await downloader.fetchManifest(baseUri);
    if (manifest.wordbookId != wordbookId || manifest.version != version) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.badManifest,
        'manifest 与任务目标不一致：'
        'manifest(wordbook=${manifest.wordbookId}, version=${manifest.version})'
        ' != task($wordbookId, $version)',
      );
    }

    await packs.markDownloading(
      wordbookId,
      version: version,
      totalSize: manifest.totalSize,
      fileCount: manifest.fileCount,
    );
    try {
      await downloader.downloadAndInstall(
        wordbookId: wordbookId,
        version: version,
        baseUri: baseUri,
        manifest: manifest,
        isCancelled: isCancelled,
        onProgress: (downloaded, total) async {
          await packs.updateProgress(wordbookId, downloaded);
        },
      );
    } on AudioPackDownloadException catch (error) {
      if (error.failure == AudioPackDownloadFailure.checksum) {
        // 校验失败不可续传：清状态，等退避后整包重下（§9.2 第 5 条）。
        await packs.reset(wordbookId);
      }
      if (error.failure != AudioPackDownloadFailure.cancelled) {
        AppLogger.error('音频包下载失败（wordbook=$wordbookId v$version）',
            error);
      }
      return false;
    }

    await packs.markReady(
      wordbookId,
      version: version,
      totalSize: manifest.totalSize,
      fileCount: manifest.fileCount,
      downloadedBytes: manifest.zipSize,
    );
    return true;
  } catch (error) {
    AppLogger.error('音频包任务失败（wordbook=$wordbookId v$version）', error);
    return false;
  } finally {
    await db.close();
  }
}
