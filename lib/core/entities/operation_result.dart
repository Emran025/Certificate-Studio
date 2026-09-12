sealed class OperationResult<T> {
  const OperationResult();

  bool get isSuccess => this is OperationSuccess<T>;

  R fold<R>({required R Function(T value) success, required R Function(String message) failure}) {
    final result = this;
    return result is OperationSuccess<T> ? success(result.value) : failure((result as OperationFailure<T>).message);
  }
}

final class OperationSuccess<T> extends OperationResult<T> {
  const OperationSuccess(this.value);

  final T value;
}

final class OperationFailure<T> extends OperationResult<T> {
  const OperationFailure(this.message);

  final String message;
}
