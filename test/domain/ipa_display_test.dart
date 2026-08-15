/// 音标展示归一化单测（TECH_DOC §10.2 音标展示与入库规范）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/ipa_display.dart';

void main() {
  group('normalizeIpaForDisplay', () {
    test('ɹ（turned r，观感为翻转的 r）规范为 r', () {
      expect(normalizeIpaForDisplay('ˈɹɛd'), 'ˈrɛd');
      expect(normalizeIpaForDisplay('ˈɹaɪt'), 'ˈraɪt');
      expect(normalizeIpaForDisplay('ˈmɪɹɝ'), 'ˈmɪrɝ');
    });

    test('ɫ（暗 l，观感为 l 带中划线）规范为 l', () {
      expect(normalizeIpaForDisplay('ˈæpəɫ'), 'ˈæpəl');
      expect(normalizeIpaForDisplay('ˈɫɛvəɫ'), 'ˈlɛvəl');
      expect(normalizeIpaForDisplay('/əˈbɪɫəˌti/'), 'əˈbɪləˌti');
    });

    test('西里尔形近字符清理：ә→ə、є→e', () {
      expect(normalizeIpaForDisplay("'seilzgә:l"), "'seilzgə:l");
      expect(normalizeIpaForDisplay("'єәrәplein"), "'eərəplein");
    });

    test('ipa-dict 自带斜杠去除，避免展示层叠加成双斜杠', () {
      expect(normalizeIpaForDisplay('/ˈstɹeɪndʒ/'), 'ˈstreɪndʒ');
      expect(normalizeIpaForDisplay('/ˈɹɛd/'), 'ˈrɛd');
    });

    test('空串、常规 IPA 与拉丁字符保持不变', () {
      expect(normalizeIpaForDisplay(''), '');
      // 学习者惯例保留集：ɡ/ɝ/ɚ 等严格 IPA 符号不做归一化。
      const sample = 'ˈæpəl ˈθɛŋk ʃɪp ɑː ɔː ʊ ɪ ɛ ŋ ʒ ð ɡ ɝ ɚ ˌ';
      expect(normalizeIpaForDisplay(sample), sample);
    });
  });
}
