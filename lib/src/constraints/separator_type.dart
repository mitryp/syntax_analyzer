enum SeparatorType {
  dot(r'[.;]'),
  comma(r','),
  condition(r'де|через');

  final String pattern;

  const SeparatorType(this.pattern);
}
