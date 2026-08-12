/// FSRS-5 官方默认参数与算法常量。
///
/// 来源：open-spaced-repetition/py-fsrs v5.1.3（FSRS-5 最终版本）`fsrs/fsrs.py`
/// 中的 `DEFAULT_PARAMETERS`、`DECAY` 与 `FUZZ_RANGES`；MIT 协议。
library;

/// FSRS-5 默认参数表 w[0..18]（py-fsrs v5.1.3 `DEFAULT_PARAMETERS`）。
///
/// 权重含义（TECH_DOC §7.4：参数首次使用官方默认值）：
/// w[0..3] 首次评分稳定性 S0(Again/Hard/Good/Easy)；w[4]/w[5] 初始难度；
/// w[6] 难度衰减；w[7] 均值回归；w[8]/w[9]/w[10] 回忆稳定性增长；
/// w[11..14] 遗忘稳定性；w[15] Hard 惩罚；w[16] Easy 加成；
/// w[17]/w[18] 短期稳定性。
const List<double> kFsrs5DefaultWeights = [
  0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046,
  1.54575, 0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315,
  2.9898, 0.51655, 0.6621,
];

/// FSRS-5 遗忘曲线衰减指数 DECAY（固定 -0.5）。
const double kFsrs5Decay = -0.5;

/// fuzz 区间表（py-fsrs v5.1.3 `FUZZ_RANGES`）：按间隔所在区间叠加比例增量，
/// 得到可允许的随机偏移范围，用于防止相邻卡片间隔扎堆。
const List<FsrsFuzzRange> kFsrs5FuzzRanges = [
  FsrsFuzzRange(start: 2.5, end: 7.0, factor: 0.15),
  FsrsFuzzRange(start: 7.0, end: 20.0, factor: 0.1),
  FsrsFuzzRange(start: 20.0, end: double.infinity, factor: 0.05),
];

/// fuzz 区间：[start, end) 内的间隔按 [factor] 计入偏移增量。
class FsrsFuzzRange {
  const FsrsFuzzRange({
    required this.start,
    required this.end,
    required this.factor,
  });

  final double start;
  final double end;
  final double factor;
}
