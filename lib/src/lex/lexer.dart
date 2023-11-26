import 'package:lexical_analyzer2/lexical_analyzer.dart';

import '../constraints/action_type.dart';
import '../constraints/geometry_attribute.dart';
import '../constraints/separator_type.dart';
import 'math_tokens.dart';

String _matchWordBases(Iterable<String> bases, [String endingPattern = '[а-яії]*']) =>
    '(${bases.join('|')})$endingPattern';

final mathLexer = ConfigurableLexer(
  rootRules: [
    const ParseRule(
      TokenType.Name,
      r'([a-z])|([A-Z][A-Z])',
      flags: RegExpFlags(caseSensitive: true),
    ),
    // line names
    const ParseRule(TokenType.Name, r'[A-Z]', flags: RegExpFlags(caseSensitive: true)),
    // point names
    const ParseRule(TokenType.Literal, Coordinates.regExpPattern),
    // coordinates literal
    ParseRule(
      TokenType.NameBuiltin, // figures
      _matchWordBases([
        'прям', // пряма
        'точ', // точка
      ]),
    ),
    ParseRule(
      TokenType.NameAttribute,
      // 'перетин', 'паралельн', 'перпендикуляр',
      _matchWordBases(GeometryAttribute.values.map((e) => e.wordBase)),
    ),
    ParseRule(
      TokenType.NameFunction,
      // 'прове', 'побуд', 'познач',
      _matchWordBases(ActionType.values.map((e) => e.wordBase)),
    ),
    const ParseRule(TokenType.Punctuation, 'r[,;.]'),
    ParseRule(TokenType.KeywordReserved, SeparatorType.condition.pattern),
  ],
);
