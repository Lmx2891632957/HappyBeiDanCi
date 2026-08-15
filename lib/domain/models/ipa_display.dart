/// 音标展示归一化（TECH_DOC §10.2 音标展示与入库规范，与内容管线
/// build_wordbook.py 保持一致，口径以文档为准）。
///
/// 归一化内容为 TECH_DOC §10.2 一次性"美式学习者惯例显示表"：
/// - ipa-dict 的严格 IPA 符号按学习者词典惯例改写：ɹ（turned r，观感"翻转的
///   r"）→ `r`、ɫ（暗 l，观感"l 带中划线"）→ `l`；
/// - ECDICT 上游音标混入的西里尔形近字符（ә/є）清理为拉丁字符；
/// - 去除 ipa-dict 原始数据自带的 `/.../`，避免与展示层包裹的斜杠叠加成
///   `//...//`；`ɡ`、`ɝ`、`ɚ` 等其余符号保留。
/// 纯逻辑、无 Flutter 依赖，便于 domain 单测。
String normalizeIpaForDisplay(String phonetic) {
  var normalized = phonetic
      .replaceAll('\u0279', 'r') // ɹ（turned r）→ r
      .replaceAll('\u026b', 'l') // ɫ（暗 l）→ l
      .replaceAll('\u04d9', '\u0259') // 西里尔 ә → 拉丁 ə
      .replaceAll('\u0454', 'e'); // 西里尔 є → 拉丁 e
  if (normalized.length >= 2 &&
      normalized.startsWith('/') &&
      normalized.endsWith('/')) {
    normalized = normalized.substring(1, normalized.length - 1);
  }
  return normalized;
}
