/// 词条领域模型（TECH_DOC §8.1 words 表）。
///
/// [meanings]/[examples] 在存储层为 JSON 文本，此处以值类型表达其结构，
/// JSON 序列化映射由 data 层负责，domain 不感知存储格式。
class Word {
  const Word({
    required this.id,
    required this.word,
    required this.phonetic,
    this.phoneticUk,
    required this.meanings,
    required this.examples,
    required this.frequency,
    this.rootAffix,
    required this.audioKey,
    this.audioUrl,
    required this.createdAt,
  });

  final int id;
  final String word;

  /// 美式 IPA 音标。
  final String phonetic;

  /// 英式 IPA 音标（M2）。
  final String? phoneticUk;

  /// 常用释义，按词频取最常用 1–3 个义项（PRD §7.1）。
  final List<WordMeaning> meanings;

  /// 例句，每词 1–2 句，需保留来源署名（Tatoeba CC BY 2.0 FR）。
  final List<WordExample> examples;
  final WordFrequency frequency;

  /// 词根词缀（JSON 可选，M2 起人工整理）。
  final String? rootAffix;

  /// 离线包内音频文件名（不含扩展名，TD-08 按词表序号命名）。
  final String audioKey;

  /// 在线兜底播放 URL（F5 在线优先）。
  final String? audioUrl;
  final DateTime createdAt;
}

/// 释义值类型：词性 + 释义文本。
class WordMeaning {
  const WordMeaning({required this.pos, required this.meaning});

  final String pos;
  final String meaning;
}

/// 例句值类型：中英对照 + 来源署名。
class WordExample {
  const WordExample({
    required this.en,
    required this.zh,
    required this.source,
    required this.attribution,
  });

  final String en;
  final String zh;
  final String source;
  final String attribution;
}

/// 高考考频（PRD F1：高/中/低频，学习时高频优先）。
enum WordFrequency {
  high,
  medium,
  low;

  /// 存储层文本值（words.frequency）。
  String get storageValue => switch (this) {
    WordFrequency.high => 'high',
    WordFrequency.medium => 'medium',
    WordFrequency.low => 'low',
  };
}
