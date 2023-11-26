enum SeparatorType {
  dot(r'[.;]'),
  comma(r',');

  final String pattern;

  const SeparatorType(this.pattern);
}
