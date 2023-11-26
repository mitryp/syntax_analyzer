bool _defaultEquals<E>(E e1, E e2) => e1 == e2;

extension IterableSplit<E> on Iterable<E> {
  Iterable<Iterable<E>> split(
    E byElement, {
    bool Function(E, E)? equals,
    bool dropEmpty = false,
  }) sync* {
    final eq = (equals ?? _defaultEquals);
    Iterable<E> rest = this;

    while (rest.isNotEmpty) {
      final part = rest.takeWhile((value) => !eq(value, byElement));
      rest = rest.skip(part.length + 1);

      if (!dropEmpty || part.isNotEmpty) {
        yield part;
      }
    }
  }
}
