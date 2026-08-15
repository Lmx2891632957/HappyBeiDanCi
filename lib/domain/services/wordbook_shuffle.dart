/// 新词乱序生成器（TECH_DOC §8.3 / TD-06）。
///
/// 设计意图：`wordbook_items.shuffled` 是"首启乱序后的学习顺序"，由确定性
/// 种子生成并持久化，保证重启/换天顺序不漂移。种子来自
/// `hash(wordbook_id, 设备安装时间)`，洗牌用纯算术的 xorshift32 +
/// Fisher–Yates，不依赖 Dart `Random` 的实现细节，同一 (seed, 词数) 恒产出
/// 同一排列（可跨进程复现、可写 golden 断言）。
abstract final class WordbookShuffle {
  WordbookShuffle._();

  /// 由词书 ID 与设备安装时间派生 32 位种子（TECH_DOC §8.3）。
  ///
  /// 实现为 FNV-1a（offset basis 2166136261、prime 16777619，非加密，仅用于
  /// 确定性乱序，不承担安全职责）；输入为 `"wordbookId:epochMs"` 的 UTF-8
  /// 字节，逐字节异或后乘 prime 并截断到 32 位。
  static int seedFor({
    required int wordbookId,
    required DateTime installTime,
  }) {
    var hash = 0x811c9dc5;
    final input = '$wordbookId:${installTime.millisecondsSinceEpoch}';
    for (final byte in input.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// 返回 `0..count-1` 的一个确定性排列（乱序序号），[seed] 相同则结果相同。
  ///
  /// 算法：xorshift32（Marsaglia 2003）作为伪随机源 + 从后向前的
  /// Fisher–Yates（Knuth shuffle）。`j = next % (i + 1)` 的取模偏差在
  /// 32 位状态空间（≤ 3677 词）下可忽略；若未来词数接近 2^32 需换
  /// 无偏拒绝采样。
  static List<int> ranks(int seed, int count) {
    if (count <= 0) {
      return const [];
    }
    final result = List<int>.generate(count, (i) => i);
    var state = seed & 0x7fffffff;
    if (state == 0) {
      // xorshift 全零状态恒为 0（序列退化），换一个非零初值兜底。
      state = 0x9e3779b9;
    }
    for (var i = count - 1; i > 0; i--) {
      state ^= (state << 13) & 0x7fffffff;
      state ^= state >>> 17;
      state ^= (state << 5) & 0x7fffffff;
      state &= 0x7fffffff;
      final j = state % (i + 1);
      final tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }
}
