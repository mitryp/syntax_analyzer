import '../../constraints/geometry_attribute.dart';
import '../../lex/math_tokens.dart';

sealed class GeometryObject {
  FigureDeclaration get declaration;

  final Map<GeometryAttribute, GeometryObject> attributeRelations = {};

  void addAttribute(GeometryAttribute attribute, {required Iterable<GeometryObject> forObjects}) {
    final objects = forObjects;

    attributeRelations.addAll({
      for (final object in objects) attribute: object,
    });
  }
}
