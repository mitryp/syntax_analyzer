import 'package:lexical_analyzer2/lexical_analyzer.dart';

String _matchWordBases(Iterable<String> bases, [String endingPattern = '[а-яії]*']) =>
    '(${bases.join('|')})$endingPattern';

final mathLexer = ConfigurableLexer(
  rootRules: [
    const ParseRule(TokenType.Name, r'[a-zA-Z]{1,2}'),
    const ParseRule(TokenType.Literal, r'\(\s*\d+\s*,\s*\d+\s*\)'), // coordinates literal
    ParseRule(
      TokenType.NameBuiltin,
      _matchWordBases([
        'прям', // пряма
        'точ', // точка
      ]),
    ),
    ParseRule(
      TokenType.NameAttribute,
      _matchWordBases([
        'перетин',
        'паралельн',
        'перпендикуляр',
      ]),
    ),
    ParseRule(
      TokenType.NameFunction,
      _matchWordBases([
        'прове', // провести,   проведіть
        'побуд', // побудувати, побудуйте
        'познач', // позначте, позначити
      ]),
    ),
  ],
);

