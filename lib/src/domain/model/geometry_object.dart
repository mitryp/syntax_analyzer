import '../../constraints/geometry_attribute.dart';
import '../../lex/math_tokens.dart';
import '../../syntax/syntax_node.dart';

sealed class GeometryObject {
  FigureDeclaration get declaration;

  List<GeometryObject> get children => [];

  const GeometryObject();

  factory GeometryObject.fromObjectNode(ObjectNodeDeclaration node) => switch (node) {
        LineNode() => Line.fromLineNode(node),
        PointNode() => Point.fromPointNode(node),
      };

  GeometryObject apply(GeometryObject object);
}

class Point extends GeometryObject {
  @override
  final PointDeclaration declaration;
  final Coordinates? coordinates;

  String? get id {
    final name = declaration.name;

    return name.isEmpty ? null : name;
  }

  const Point(this.declaration, [this.coordinates]);

  factory Point.fromPointNode(PointNode node) {
    final decl = PointDeclaration(name: node.name, id: -1);

    return Point(decl, node.coordinates);
  }

  Point withCoordinates(Coordinates coordinates) => Point(declaration, coordinates);

  @override
  GeometryObject apply(GeometryObject object) {
    if (object is! Point || object.id != id || coordinates != null || object.coordinates == null) {
      return this;
    }

    return withCoordinates(object.coordinates!);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          declaration == other.declaration &&
          coordinates == other.coordinates;

  @override
  int get hashCode => declaration.hashCode ^ coordinates.hashCode;

  @override
  String toString() => 'Point{declaration: $declaration, coordinates: $coordinates}';
}

class Line extends GeometryObject {
  String? get name {
    final name = declaration.name;

    return name.isNotEmpty ? name : null;
  }

  @override
  List<GeometryObject> get children => [points.$1, points.$2].nonNulls.toList(growable: false);

  @override
  final LineDeclaration declaration;

  final (Point?, Point?) points;

  final List<(GeometryAttribute, GeometryObject)> attributeRelations = [];

  (String?, String?) get pointIds {
    final name = this.name;
    final ids = (points.$1?.id, points.$2?.id);

    if (name == null || name.length != 2) {
      return ids;
    }

    final [p1Name, p2Name] = name.split('');

    return (ids.$1 ?? p1Name, ids.$2 ?? p2Name);
  }

  Line(this.declaration, [this.points = (null, null)]);

  factory Line.fromLineNode(LineNode node) {
    final decl = LineDeclaration(name: node.name, id: -1);

    return Line(decl);
  }

  void addAttribute(GeometryAttribute attribute, {required Iterable<GeometryObject> forObjects}) {
    final objects = forObjects;

    attributeRelations.addAll({
      for (final object in objects) (attribute, object),
    });
  }

  Line assignPoint(Point p) {
    final newPoints = switch (points) {
      (null, final p1) when p1 != p => (p, p1),
      (final p1, null) when p1 != p => (p1, p),
      _ => points, // cannot assign a new point to a line which already has both points assigned
    };

    return newPoints == points ? this : Line(declaration, newPoints);
  }

  Line withPoints((Point, Point) points) => Line(declaration, points);

  @override
  Line apply(GeometryObject object) {
    if (object is! Line || object.name != name || object.points == points) {
      return this;
    }

    final (p1, p2) = object.points;

    return [p1, p2].nonNulls.fold(this, (prev, el) => prev.assignPoint(el));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Line &&
          runtimeType == other.runtimeType &&
          declaration == other.declaration &&
          points == other.points &&
          attributeRelations == other.attributeRelations;

  @override
  int get hashCode => declaration.hashCode ^ points.hashCode ^ attributeRelations.hashCode;

  @override
  String toString() =>
      'Line{declaration: $declaration, points: $points, attributeRelations: $attributeRelations}';
}
