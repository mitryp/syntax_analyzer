import '../../constraints/geometry_attribute.dart';
import '../../lex/math_tokens.dart';

sealed class GeometryObject {
  FigureDeclaration get declaration;

  const GeometryObject();
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

  Point withCoordinates(Coordinates coordinates) => Point(declaration, coordinates);
}

class Line extends GeometryObject {
  @override
  final LineDeclaration declaration;

  final (Point?, Point?) points;

  final Map<GeometryAttribute, GeometryObject> attributeRelations = {};

  (String?, String?) get pointIds => (points.$1?.id, points.$2?.id);

  Line(this.declaration, [this.points = (null, null)]);

  void addAttribute(GeometryAttribute attribute, {required Iterable<GeometryObject> forObjects}) {
    final objects = forObjects;

    attributeRelations.addAll({
      for (final object in objects) attribute: object,
    });
  }

  Line assignPoint(Point p) {
    final newPoints = switch (points) {
      (null, final p1) => (p, p1),
      (final p1, null) => (p1, p),
      _ => points, // cannot assign a new point to a line which already has both points assigned
    };

    return newPoints == points ? this : Line(declaration, newPoints);
  }
}
