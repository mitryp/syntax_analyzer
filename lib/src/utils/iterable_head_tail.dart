extension IterableHeadTail<E> on Iterable<E> {
  (E head, Iterable<E> tail) headTail() => (first, skip(1));
}
