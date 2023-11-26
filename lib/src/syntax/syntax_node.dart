import '../constraints/action_type.dart';
import '../constraints/figure_type.dart';
import '../constraints/geometry_attribute.dart';
import '../constraints/separator_type.dart';
import '../domain/errors/syntax_error.dart';
import '../lex/lexical_analyzer.dart';
import '../lex/math_tokens.dart';
import '../utils/iterable_head_tail.dart';
import '../utils/iterable_split.dart';

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
      RootNode.tryParse(tokens)?.$1 ?? (throw SyntaxError('Something went wrong'));
}

class RootNode implements SyntaxNode {
  final List<ActionNode> actions;
  final List<ConditionNode> conditions;

  RootNode({required this.actions, required this.conditions});

  static NodeParseResult<RootNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final separated = tokens.split(const DeclarationSeparator.conditions());
    if (separated.length > 2) {
      throw SyntaxError('Підтримується не більше однієї умови');
    }

    final actionsTokens = separated.first;
    final conditionsTokens = separated.length == 2 ? separated.elementAt(1) : <MathToken>[];

    final (actions, restTokens) = _fillListWhileParses(actionsTokens, ActionNode.tryParse);

    if (actions.isEmpty) {
      throw SyntaxError('Жодної дії не задано');
    }

    if (restTokens.isNotEmpty) {
      throw SyntaxError('Зайві токени після списку визначень: $restTokens');
    }

    final (conditions, leftoverTokens) =
        _fillListWhileParses(conditionsTokens, ConditionNode.tryParse);

    if (leftoverTokens.isNotEmpty) {
      throw SyntaxError('Зайві токени після умови: $leftoverTokens');
    }

    return (RootNode(actions: actions, conditions: conditions), []);
  }

  @override
  String toString() => '''Root(
      actions: $actions
      conditions: $conditions
    )''';
}

class ConditionNode implements SyntaxNode {
  final ObjectNode object;
  final List<PropertyNode> properties;

  const ConditionNode({required this.object, required this.properties});

  static NodeParseResult<ConditionNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final objParseRes = ObjectNode.tryParse(tokens);

    if (objParseRes == null) {
      return null;
    }

    final (obj, rest1) = objParseRes;
    final (props, rest2) = _fillListWhileParses(rest1, (tokens) {
      return PropertyNode.tryParse(
        tokens.skipWhile((token) {
          if (token case DeclarationSeparator(type: SeparatorType.comma)) {
            return true;
          }

          return false;
        }),
      );
    });

    return (ConditionNode(object: obj, properties: props), rest2);
  }

  @override
  String toString() => '''Condition(
      object: $object
      properties: $properties
    )''';
}

class ActionNode implements SyntaxNode {
  final ActionType operation;
  final List<DeclarationNode> declarations;

  const ActionNode({required this.operation, required this.declarations});

  static NodeParseResult<ActionNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (actionDecl, tail) = tokens.headTail();

    if (actionDecl is! ActionDeclaration) {
      return null;
    }

    final operation = actionDecl.actionType;

    final (declarations, restTokens) = _fillListWhileParses(tail, DeclarationNode.tryParse);

    if (declarations.isEmpty) {
      return null;
    }

    return (ActionNode(operation: operation, declarations: declarations), restTokens);
  }

  @override
  String toString() => '''Action(
      operation: $operation
      declarations: $declarations
    )''';
}

class DeclarationNode implements SyntaxNode {
  final List<(ObjectNode, PropertyNode?)> declarations;

  const DeclarationNode({required this.declarations});

  static NodeParseResult<DeclarationNode>? tryParse(Iterable<MathToken> tokens) {
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

      final objParseRes = ObjectNode.tryParse(stripped);

      if (objParseRes == null) {
        return null;
      }

      final (obj, rest1) = objParseRes;
      final (prop, rest2) = PropertyNode.tryParse(rest1) ?? (null, null);

      return ((obj, prop), rest2 ?? rest1);
    });

    if (declarations.isEmpty) {
      return null;
    }

    return (DeclarationNode(declarations: declarations), restTokens);
  }

  @override
  String toString() => '''Declaration(
      $declarations
    )''';
}

class PropertyNode implements SyntaxNode {
  final GeometryAttribute attribute;
  final ObjectNode target;

  const PropertyNode({required this.attribute, required this.target});

  static NodeParseResult<PropertyNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.length < 2) {
      return null;
    }

    final (attribute, tail) = tokens.headTail();
    final lineParseRes = ObjectNode.tryParse(tail);

    if (attribute is! FigureAttribute ||
        lineParseRes == null ||
        lineParseRes.$1.figureType != FigureType.line) {
      return null;
    }

    final (line, restTokens) = lineParseRes;

    return (PropertyNode(attribute: attribute.attribute, target: line), restTokens);
  }

  @override
  String toString() => 'Property($attribute -> $target)';
}

class ObjectNode implements SyntaxNode {
  final FigureType figureType;
  final List<ObjectNodeDeclaration> declarations;

  const ObjectNode({required this.figureType, required this.declarations});

  static NodeParseResult<ObjectNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    var (first, tail) = tokens.headTail();
    final FigureType type;

    switch (first) {
      case FigureDeclaration(type: final figureType) ||
            FigureTypeDeclaration(type: final figureType):
        type = figureType;
      default:
        return null;
    }

    if (first is FigureDeclaration) {
      tail = [first, ...tail];
    }

    final parser = type == FigureType.point ? PointNode.tryParse : LineNode.tryParse;

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
      ObjectNode(declarations: declarations, figureType: type),
      restTokens,
    );
  }

  @override
  String toString() => '''Object(
      figureType: $figureType
      declarations: $declarations
    )''';
}

sealed class ObjectNodeDeclaration implements SyntaxNode {
  String get name;
}

class PointNode implements ObjectNodeDeclaration {
  @override
  final String name;
  final Coordinates? coordinates;

  const PointNode({required this.name, this.coordinates});

  static NodeParseResult<PointNode>? tryParse(Iterable<MathToken> tokens) {
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
      PointNode(name: head.name, coordinates: coords),
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

class LineNode implements ObjectNodeDeclaration {
  @override
  final String name;

  const LineNode({required this.name});

  static NodeParseResult<LineNode>? tryParse(Iterable<MathToken> tokens) {
    if (tokens.isEmpty) {
      return null;
    }

    final (head, tail) = tokens.headTail();

    if (head is! LineDeclaration) {
      return null;
    }

    return (
      LineNode(name: head.name),
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
  const str = 'провести пряму'; //. провести пряму CD, паралельну прямій AB';
  // 'позначте точку A(1,2)';
  final tokens = parse(str);
  final obj = SyntaxNode.buildSyntaxAnalysisTree(tokens);
  print(obj);
}
