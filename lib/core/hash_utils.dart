import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// 文件哈希工具：分块流式 SHA-256，50–100 MB 级文件不整读入内存。
abstract final class Sha256Utils {
  Sha256Utils._();

  static String fileSha256(File file) {
    final raf = file.openSync();
    final collector = _DigestCollector();
    final sink = sha256.startChunkedConversion(collector);
    final chunk = Uint8List(1 << 16);
    try {
      while (true) {
        final read = raf.readIntoSync(chunk);
        if (read == 0) {
          break;
        }
        sink.add(chunk.sublist(0, read));
      }
    } finally {
      raf.closeSync();
    }
    sink.close();
    return collector.digest.toString();
  }
}

/// 收集哈希转换器的唯一输出（crypto 3.x 未公开 DigestSink，避免依赖内部
/// `src/` 导入，按 `Sink<Digest>` 契约自行实现）。
class _DigestCollector implements Sink<Digest> {
  Digest? _digest;

  Digest get digest => _digest!;

  @override
  void add(Digest data) => _digest = data;

  @override
  void close() {}
}
