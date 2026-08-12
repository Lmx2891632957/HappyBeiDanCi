/// 统一的返回值类型：显式表达“可能失败”，避免用异常或 null 表达业务错误。
///
/// 设计意图：仓储/服务层失败信息需要携带给 UI 展示，而异常会被 Riverpod
/// 的 async 链路吞掉上下文；后续所有可能失败的调用统一返回 [Result]。
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
