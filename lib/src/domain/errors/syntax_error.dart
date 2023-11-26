class SyntaxError extends StateError {
  SyntaxError(super.message);

  @override
  String toString() => 'SyntaxError($message)';
}
