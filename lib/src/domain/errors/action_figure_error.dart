import '../../constraints/action_type.dart';
import '../../constraints/figure_type.dart';

/// Is thrown when the [ActionType] is not compatible with the next declared [FigureType].
class ActionFigureError extends TypeError {
  final ActionType actionType;
  final FigureType figureType;

  ActionFigureError(this.actionType, this.figureType);

  @override
  String toString() => 'IncompatibleTypeError($actionType <==> $figureType)';
}
