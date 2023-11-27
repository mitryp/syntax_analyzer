import '../constraints/geometry_attribute.dart';
import '../domain/model/geometry_object.dart';
import '../lex/math_tokens.dart';
import '../syntax/syntax_node.dart';

typedef Condition = (GeometryObject, Iterable<(GeometryAttribute, GeometryObject)>);

class TreeParser {
  final RootNode root;
  final Set<GeometryObject> declaredObjects = {};
  final Map<String, GeometryObject> namedObjects = {};

  TreeParser(this.root);

  void parse([SyntaxNode? node]) {
    node ??= root;

    switch (node) {
      case RootNode(actions: final actions, conditions: final rootConditions):
        actions.forEach(parse);
        _applyConditions(rootConditions.map((cn) => cn.toCondition()));
      case ConditionNode():
        _applyConditions([node.toCondition()]);
      case ActionNode(declarationNodes: final declarationNodes):
        declarationNodes.forEach(parse);
      case DeclarationNode(declarations: final declarations):
        declarations.map((d) => d.$1).forEach((n) => _updateObjects(fromNode: n));
      case ObjectNode():
        _updateObjects(fromNode: node);
      default:
        // others should be parsed by this time
        print('skipping node $node');
        return;
    }
  }

  void _applyConditions(Iterable<Condition> conditions) {
    for (final (object, properties) in conditions) {
      if (object is! Line) {
        continue;
      }

      for (final (attribute, target) in properties) {
        object.addAttribute(attribute, forObjects: [target]);
      }

      _updateObject(object);
    }
  }

  void _updateObjects({required ObjectNode fromNode}) {
    final objects = fromNode.declarations.map(GeometryObject.fromObjectNode);

    objects.forEach(_updateObject);
  }

  void _updateObject(GeometryObject object) {
    final name = object.declaration.name;
    final existingObject = name.isNotEmpty ? namedObjects[name] : null;

    if (existingObject == null) {
      namedObjects[name] = object;
      declaredObjects.add(object);

      object.children.where((child) => !_objectIsRegistered(child)).forEach(_updateObject);

      // create unknown points in lines
      if (object is Line) {
        final (p1Name, p2Name) = object.pointIds;
        final pNames = [p1Name, p2Name].nonNulls.where(
              (e) => e.isNotEmpty && namedObjects[e] == null,
            );

        for (final pName in pNames) {
          final p = Point(PointDeclaration(name: pName, id: -1));
          _updateObject(p);
        }
      }

      if (object is Point) {
        final declaredObjects = this.declaredObjects.toList(growable: false);
        final referringLines =
            declaredObjects.whereType<Line>().where((l) => _pairContains(l.pointIds, object.id));

        for (final line in referringLines) {
          _updateObject(line.assignPoint(object));
        }
      }

      return;
    }

    final applied = existingObject.apply(object);
    declaredObjects.add(applied);
    if (name.isNotEmpty) {
      namedObjects[name] = applied;
    }

    applied.children.where((child) => !_objectIsRegistered(child)).forEach(_updateObject);
  }

  bool _objectIsRegistered(GeometryObject object) {
    final name = object.declaration.name;

    return (name.isNotEmpty && namedObjects[name] != null) || declaredObjects.contains(object);
  }
}

bool _pairContains<E>((E, E) pair, E element) => pair.$1 == element || pair.$2 == element;

extension on ConditionNode {
  Condition toCondition() {
    final object = GeometryObject.fromObjectNode(objectDeclaration);

    return (object, properties.map((p) => (p.attribute, GeometryObject.fromObjectNode(p.target))));
  }
}
