import 'package:lexical_analyzer2/lexical_analyzer.dart';

import '../constants.dart';
import '../constraints/action_type.dart';
import '../constraints/figure_type.dart';
import '../constraints/geometry_attribute.dart';
import '../constraints/separator_type.dart';

sealed class MathToken {
  static const List<MathToken? Function(LexerToken token)> parsers = [
    Coordinates.tryParse,
    FigureTypeDeclaration.tryParse,
    FigureDeclaration.tryParse,
    FigureAttribute.tryParse,
    ActionDeclaration.tryParse,
    DeclarationSeparator.tryParse,
  ];

  static MathToken tryParse(LexerToken token) {
    for (final parser in parsers) {
      if (parser(token) case final res?) return res;
    }

    throw token; // check
  }

  String? get tokenText;
}

class Coordinates implements MathToken {
  static const String regExpPattern = r'\(\s*(\d+)\s*,\s*(\d+)\s*\)';

  @override
  final String? tokenText;

  final int x;
  final int y;

  const Coordinates(this.x, this.y, {this.tokenText});

  static Coordinates? tryParse(LexerToken token) {
    if (token.type != TokenType.Literal) {
      return null;
    }

    final match = RegExp(regExpPattern).firstMatch(token.text);

    if (match == null) {
      return null;
    }

    final (strX, strY) = (match.group(1), match.group(2));

    return strX == null || strY == null
        ? null
        : Coordinates(int.parse(strX), int.parse(strY), tokenText: match.group(0));
  }

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinates && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

class FigureTypeDeclaration implements MathToken {
  @override
  final String? tokenText;

  final FigureType type;

  const FigureTypeDeclaration(this.type, {this.tokenText});

  static FigureTypeDeclaration? tryParse(LexerToken token) {
    if (token.type != TokenType.NameBuiltin) {
      return null;
    }

    final str = token.text.toLowerCase();
    final type = FigureType.values.where((e) => str.startsWith(e.wordBase)).firstOrNull;

    return type == null ? null : FigureTypeDeclaration(type, tokenText: token.text);
  }

  @override
  String toString() => 'FigureTypeDeclaration($type)';
}

sealed class FigureDeclaration implements MathToken {
  String get name;

  int get id;

  FigureType get type => typeOf(this);

  const FigureDeclaration();

  String represent();

  static FigureDeclaration? tryParse(LexerToken token) =>
      PointDeclaration.tryParse(token) ?? LineDeclaration.tryParse(token);

  static FigureType typeOf(FigureDeclaration declaration) => switch (declaration) {
        PointDeclaration() => FigureType.point,
        LineDeclaration() => FigureType.line,
      };
}

class PointDeclaration extends FigureDeclaration {
  @override
  final String? tokenText;

  @override
  final int id;

  @override
  final String name;

  const PointDeclaration({required this.name, required this.id, this.tokenText});

  const PointDeclaration.root() : this(name: '', id: rootPointId, tokenText: 'root_point');

  static PointDeclaration? tryParse(LexerToken token) {
    if (token is! IdentifierLexerToken) {
      return null;
    }

    final str = token.text;

    if (str.length != 1 || !RegExp(r'[A-Z]').hasMatch(str[0])) {
      return null;
    }

    return PointDeclaration(name: str, id: token.id, tokenText: str);
  }

  @override
  String represent() => name;

  @override
  String toString() => 'Point ${name.isEmpty ? tokenText : name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointDeclaration &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class LineDeclaration extends FigureDeclaration {
  @override
  final String? tokenText;

  @override
  final int id;

  @override
  final String name;

  const LineDeclaration({required this.name, required this.id, this.tokenText});

  const LineDeclaration.root() : this(name: '', id: rootLineId, tokenText: 'root_line');

  static LineDeclaration? tryParse(LexerToken token) {
    if (token is! IdentifierLexerToken) {
      return null;
    }

    final str = token.text;

    if (str.isEmpty || str.length > 2 || !RegExp(r'[A-Z]{2}|[a-z]').hasMatch(str)) {
      return null;
    }

    return LineDeclaration(name: str, id: token.id, tokenText: str);
  }

  @override
  String represent() => name;

  @override
  String toString() => 'Line ${name.isEmpty ? tokenText : name}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineDeclaration &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class FigureAttribute implements MathToken {
  @override
  final String? tokenText;

  final GeometryAttribute attribute;

  const FigureAttribute(this.attribute, {this.tokenText});

  static FigureAttribute? tryParse(LexerToken token) {
    if (token.type != TokenType.NameAttribute) {
      return null;
    }

    final str = token.text.toLowerCase();
    final attribute = GeometryAttribute.values.where((e) => str.startsWith(e.wordBase)).firstOrNull;

    return attribute == null ? null : FigureAttribute(attribute, tokenText: token.text);
  }

  @override
  String toString() => 'FigureAttribute($attribute)';
}

class ActionDeclaration implements MathToken {
  @override
  final String? tokenText;

  final ActionType actionType;

  const ActionDeclaration(this.actionType, {this.tokenText});

  static ActionDeclaration? tryParse(LexerToken token) {
    if (token.type != TokenType.NameFunction) {
      return null;
    }

    final str = token.text.toLowerCase();
    final actionType = ActionType.values.where((e) => str.startsWith(e.wordBase)).firstOrNull;

    return actionType == null ? null : ActionDeclaration(actionType, tokenText: token.text);
  }

  @override
  String toString() => 'ActionDeclaration($actionType)';
}

class DeclarationSeparator implements MathToken {
  @override
  final String? tokenText;

  final SeparatorType type;

  const DeclarationSeparator(this.type, {this.tokenText});

  const DeclarationSeparator.actions({this.tokenText}) : type = SeparatorType.dot;

  const DeclarationSeparator.declarations({this.tokenText}) : type = SeparatorType.comma;

  const DeclarationSeparator.conditions({this.tokenText}) : type = SeparatorType.condition;

  static DeclarationSeparator? tryParse(LexerToken token) {
    if (token.type != TokenType.Punctuation && token.type != TokenType.KeywordReserved) {
      return null;
    }

    final tokenText = token.text;

    final type = SeparatorType.values
        .where(
          (type) => RegExp(type.pattern).hasMatch(tokenText),
        )
        .firstOrNull;

    if (type == null) {
      return null;
    }

    return DeclarationSeparator(type, tokenText: tokenText);
  }

  @override
  String toString() => 'DeclarationSeparator';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeclarationSeparator && runtimeType == other.runtimeType && type == other.type;

  @override
  int get hashCode => type.hashCode;
}
