import 'package:lexical_analyzer2/lexical_analyzer.dart';

import '../constraints/action_type.dart';
import '../constraints/figure_type.dart';
import '../constraints/geometry_attribute.dart';
import '../domain/errors/action_figure_error.dart';
import '../domain/errors/declaration_type_error.dart';
import 'lexer.dart';
import 'math_tokens.dart';

Iterable<MathToken> parse(String input) sync* {
  final wrapper = LexerWrapper.forLexer(
    source: input,
    lexer: mathLexer,
    tokenFilter: (t) => t != TokenType.Error && t != TokenType.Text,
  );

  final tokens = wrapper.analyze().tokens;

  if (tokens.isEmpty) {
    return;
  }

  final mathTokens = tokens.map(MathToken.tryParse);

  PointDeclaration lastPoint = const PointDeclaration.root();
  LineDeclaration lastLine = const LineDeclaration.root();
  MathToken? prev;
  for (final cur in mathTokens) {
    switch ((prev, cur)) {
      case (
                FigureTypeDeclaration(type: final declarationType),
                FigureDeclaration(type: final declaredType),
              ) ||
              (
                FigureDeclaration(type: final declarationType),
                FigureDeclaration(type: final declaredType),
              )
          when declaredType != declarationType:
        throw DeclarationTypeError(declarationType: declarationType, declaredType: declaredType);
      case (
            ActionDeclaration(actionType: final actionType),
            FigureDeclaration(type: final figureType)
          )
          when !actionType.doesSupport(figureType):
        throw ActionFigureError(actionType, figureType);
      case (FigureTypeDeclaration(), FigureTypeDeclaration()):
        yield switch ((prev as FigureTypeDeclaration).type) {
          FigureType.point => lastPoint,
          FigureType.line || FigureType.perpendicular => lastLine,
        };
        yield cur;
        break;
      case (_, PointDeclaration()):
        lastPoint = cur as PointDeclaration;
        yield cur;
        break;
      case (_, LineDeclaration()):
        cur as LineDeclaration;
        lastLine = cur;

        if (cur.type == FigureType.perpendicular) {
          yield const FigureAttribute(GeometryAttribute.perpendicular);
        }
        yield cur;
        break;
      default:
        yield cur;
        break;
    }

    prev = cur;
  }

  if (prev case FigureTypeDeclaration(type: final lastType)) {
    yield switch (lastType) {
      FigureType.point => lastPoint,
      FigureType.line || FigureType.perpendicular => lastLine,
    };
  }
}

extension on ActionType {
  bool doesSupport(FigureType figureType) => switch (figureType) {
        FigureType.point => this == ActionType.drawAPoint,
        FigureType.line => this == ActionType.drawALine,
        FigureType.perpendicular => this == ActionType.drawAPerpendicular,
      };
}
