/// 音标展示归一化（TECH_DOC §10.2 音标展示与入库规范，与内容管线
/// build_wordbook.py 保持一致，口径以文档为准）。
///
/// 解决两类观感问题：
/// 1. ipa-dict 使用严格 IPA 的 ɹ（U+0279，turned r），观感为"翻转的 r"，
///    学习者词典惯例使用普通 `r`；
/// 2. ECDICT 上游音标混入西里尔形近字符（ә/є），部分字体下显示异常。
/// 纯逻辑、无 Flutter 依赖，便于 domain 单测。
String normalizeIpaForDisplay(String phonetic) {
  return phonetic
      .replaceAll('\u0279', 'r') // ɹ（turned r）→ r
      .replaceAll('\u04d9', '\u0259') // 西里尔 ә → 拉丁 ə
      .replaceAll('\u0454', 'e'); // 西里尔 є → 拉丁 e
}
