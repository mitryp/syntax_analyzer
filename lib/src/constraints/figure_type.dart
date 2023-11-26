import '../constants.dart';

enum FigureType {
  point('точ', rootPointId),
  line('прям', rootLineId),
  perpendicular('перпендикуляр', rootLineId);

  final String wordBase;
  final int rootId;

  const FigureType(this.wordBase, this.rootId);
}
