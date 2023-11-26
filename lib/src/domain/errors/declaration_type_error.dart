import '../../constraints/figure_type.dart';

class DeclarationTypeError extends TypeError {
  final FigureType declarationType;
  final FigureType declaredType;

  DeclarationTypeError({required this.declarationType, required this.declaredType});

  @override
  String toString() => 'DeclarationTypeError($declaredType -> $declarationType)';
}
