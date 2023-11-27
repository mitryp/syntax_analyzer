import 'domain/model/geometry_object.dart';
import 'lex/lexical_analyzer.dart';
import 'syntax/syntax_node.dart';
import 'tree_parser/tree_parser.dart';

Iterable<GeometryObject> analyze(String input) {
  final tokens = parse(input);
  final tree = SyntaxNode.buildSyntaxAnalysisTree(tokens);

  final tp = TreeParser(tree as RootNode)..parse();

  return tp.declaredObjects;
}
