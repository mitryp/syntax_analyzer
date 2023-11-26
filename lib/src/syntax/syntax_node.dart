import '../constraints/action_type.dart';
import '../constraints/figure_type.dart';
import '../constraints/geometry_attribute.dart';
import '../constraints/separator_type.dart';
import '../domain/errors/syntax_error.dart';
import '../lex/lexical_analyzer.dart';
import '../lex/math_tokens.dart';
import '../utils/iterable_head_tail.dart';

typedef ParseResult<R> = (R res, Iterable<MathToken> other);
typedef NodeParseResult<N extends SyntaxNode> = ParseResult<N>;

(List<N> nodes, Iterable<MathToken> other) _fillListWhileParses<N extends SyntaxNode>(
  Iterable<MathToken> tokens,
  NodeParseResult<N>? Function(Iterable<MathToken> tokens) nodeParser,
) {
  final List<N> nodeList = [];
  var rest = tokens;

  do {
    final parseRes = nodeParser(rest);

    if (parseRes?.$1 == null) {
      break;
    }

    if (parseRes != null) {
      final (node, other) = parseRes;

      nodeList.add(node);
      rest = other;
    }
  } while (true);

  return (nodeList, rest);
}

(List<R> list, Iterable<MathToken> other) _parseUntilNull<R extends Object>(
  Iterable<MathToken> tokens,
  ParseResult<R>? Function(Iterable<MathToken>) parser,
) {
  var rest = tokens;
  final list = <R>[];

  R? res;
  do {
    final r = parser(rest);
    res = r?.$1;

    if (r != null) {
      list.add(r.$1);
      rest = r.$2;
    }
  } while (res != null);

  return (list, rest);
}

sealed class SyntaxNode {
  factory SyntaxNode.buildSyntaxAnalysisTree(Iterable<MathToken> tokens) =>
      _RootNode.tryParse(tokens)?.$1 ?? (throw SyntaxError('Something went wrong'));
}

class _RootNode implements SyntaxNode {
  final List<_ActionDeclarationNode> actionDeclarations;
  final List<_ConditionNode> conditions;

  _RootNode({required this.actionDeclarations, required this.conditions});

  static NodeParseResult<_RootNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (declarations, restTokens) =
        _fillListWhileParses(tokens, _ActionDeclarationNode.tryParse);

    if (declarations.isEmpty) {
      throw SyntaxError('Жодної дії не задано');
    }

    final (conditions, leftoverTokens) = _fillListWhileParses(restTokens, _ConditionNode.tryParse);

    return (_RootNode(actionDeclarations: declarations, conditions: conditions), leftoverTokens);
  }

  @override
  String toString() => '''Root(
      actionDeclarations: $actionDeclarations
      conditions: $conditions
    )''';
}

class _ActionDeclarationNode implements SyntaxNode {
  final _ActionNode action;
  final List<_DeclarationNode> declarations;

  const _ActionDeclarationNode({required this.action, required this.declarations});

  static NodeParseResult<_ActionDeclarationNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final actionParseRes = _ActionNode.tryParse(tokens);

    if (actionParseRes == null) {
      return null;
    }

    final (action, rest1) = actionParseRes;
    final (declarations, rest2) = _fillListWhileParses(rest1, (tokens) {
      return _DeclarationNode.tryParse(
        tokens.skipWhile((token) {
          if (token case DeclarationSeparator(type: SeparatorType.dot)) {
            return true;
          }

          return false;
        }),
      );
    });

    // if (declarations.isEmpty) {
    //   return null;
    // }

    return (_ActionDeclarationNode(action: action, declarations: declarations), rest2);
  }

  @override
  String toString() => '''ActionDeclaration(
      action: $action
      declarations: $declarations
    )''';
}

class _ConditionNode implements SyntaxNode {
  final _ObjectNode object;
  final List<_PropertyNode> properties;

  const _ConditionNode({required this.object, required this.properties});

  static NodeParseResult<_ConditionNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final objParseRes = _ObjectNode.tryParse(tokens);

    if (objParseRes == null) {
      return null;
    }

    final (obj, rest1) = objParseRes;
    final (props, rest2) = _fillListWhileParses(rest1, (tokens) {
      return _PropertyNode.tryParse(
        tokens.skipWhile((token) {
          if (token case DeclarationSeparator(type: SeparatorType.comma)) {
            return true;
          }

          return false;
        }),
      );
    });

    return (_ConditionNode(object: obj, properties: props), rest2);
  }

  @override
  String toString() => '''Condition(
      object: $object
      properties: $properties
    )''';
}

class _ActionNode implements SyntaxNode {
  final ActionType operation;
  final List<_DeclarationNode> declarations;

  const _ActionNode({required this.operation, required this.declarations});

  static NodeParseResult<_ActionNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (actionDecl, tail) = tokens.headTail();

    if (actionDecl is! ActionDeclaration) {
      return null;
    }

    final operation = actionDecl.actionType;

    final (declarations, restTokens) = _fillListWhileParses(tail, _DeclarationNode.tryParse);

    if (declarations.isEmpty) {
      return null;
    }

    return (_ActionNode(operation: operation, declarations: declarations), restTokens);
  }

  @override
  String toString() => '''Action(
      operation: $operation
      declarations: $declarations
    )''';
}

class _DeclarationNode implements SyntaxNode {
  final List<(_ObjectNode, _PropertyNode?)> declarations;

  const _DeclarationNode({required this.declarations});

  static NodeParseResult<_DeclarationNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (declarations, restTokens) = _parseUntilNull(tokens, (tokens) {
      final stripped = tokens.skipWhile((token) {
        if (token case DeclarationSeparator(type: SeparatorType.comma)) {
          return true;
        }

        return false;
      });

      final objParseRes = _ObjectNode.tryParse(stripped);

      if (objParseRes == null) {
        return null;
      }

      final (obj, rest1) = objParseRes;
      final (prop, rest2) = _PropertyNode.tryParse(rest1) ?? (null, null);

      return ((obj, prop), rest2 ?? rest1);
    });

    if (declarations.isEmpty) {
      return null;
    }

    return (_DeclarationNode(declarations: declarations), restTokens);
  }

  @override
  String toString() => '''Declarations(
      $declarations
    )''';
}

class _PropertyNode implements SyntaxNode {
  final GeometryAttribute attribute;
  final _ObjectNode target;

  const _PropertyNode({required this.attribute, required this.target});

  static NodeParseResult<_PropertyNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.length < 2) {
      return null;
    }

    final (attribute, tail) = tokens.headTail();
    final lineParseRes = _ObjectNode.tryParse(tail);

    if (attribute is! FigureAttribute ||
        lineParseRes == null ||
        lineParseRes.$1.figureType != FigureType.line) {
      return null;
    }

    final (line, restTokens) = lineParseRes;

    return (_PropertyNode(attribute: attribute.attribute, target: line), restTokens);
  }

  @override
  String toString() => 'Property($attribute -> $target)';
}

class _ObjectNode implements SyntaxNode {
  final FigureType figureType;
  final List<_ObjectNodeDeclaration> declarations;

  const _ObjectNode({required this.figureType, required this.declarations});

  static NodeParseResult<_ObjectNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (typeDecl, tail) = tokens.headTail();

    if (typeDecl is! FigureTypeDeclaration) {
      return null;
    }

    final parser = typeDecl.type == FigureType.point ? _PointNode.tryParse : _LineNode.tryParse;

    final (declarations, restTokens) = _fillListWhileParses(tail, (tokens) {
      return parser(
        tokens.skipWhile((token) {
          if (token case DeclarationSeparator(type: SeparatorType.comma)) {
            return true;
          }

          return false;
        }),
      );
    });

    if (declarations.isEmpty) {
      throw SyntaxError('Жодної декларації не надано');
    }

    return (
      _ObjectNode(declarations: declarations, figureType: typeDecl.type),
      restTokens,
    );
  }

  @override
  String toString() => '''Object(
      figureType: $figureType
      declarations: $declarations
    )''';
}

sealed class _ObjectNodeDeclaration implements SyntaxNode {
  String get name;

  static FigureType typeOf(_ObjectNodeDeclaration decl) => switch (decl) {
        _PointNode() => FigureType.point,
        _LineNode() => FigureType.line,
      };
}

class _PointNode implements _ObjectNodeDeclaration {
  @override
  final String name;
  final Coordinates? coordinates;

  const _PointNode({required this.name, this.coordinates});

  static NodeParseResult<_PointNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (head, tail) = tokens.headTail();

    if (head is! PointDeclaration) {
      return null;
    }

    final next = tail.firstOrNull;
    final coords = next is Coordinates ? next : null;

    return (
      _PointNode(name: head.name, coordinates: coords),
      tail.skip(coords != null ? 1 : 0).skipWhile((token) {
        if (token case DeclarationSeparator(type: SeparatorType.comma)) {
          return true;
        }

        return false;
      }),
    );
  }

  @override
  String toString() => 'Point($name, $coordinates)';
}

class _LineNode implements _ObjectNodeDeclaration {
  @override
  final String name;

  const _LineNode({required this.name});

  static NodeParseResult<_LineNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (head, tail) = tokens.headTail();

    if (head is! LineDeclaration) {
      return null;
    }

    return (
      _LineNode(name: head.name),
      tail.skipWhile((token) {
        if (token case DeclarationSeparator(type: SeparatorType.comma)) {
          return true;
        }

        return false;
      }),
    );
  }

  @override
  String toString() => 'Line($name)';
}

void main() {
  const str = 'провести пряму AB, паралельну прямій CD.';

  final tokens = parse(str);
  final obj = SyntaxNode.buildSyntaxAnalysisTree(tokens);
  print(obj);
}
